//
//  CameraViewModel.swift
//  RetroFilm
//
//  Owns the AVCaptureSession and drives a LIVE, filter-previewed feed.
//
//  Approach: a video-data output streams frames; each frame is pushed through
//  the film pipeline (preview quality) and published as a CGImage that the
//  SwiftUI viewfinder draws. A separate photo output captures a full-resolution
//  still that is rendered at export quality. This keeps WYSIWYG between the
//  viewfinder and the saved photo.
//
//  Concurrency: the capture-delegate callbacks run on AVFoundation's queues,
//  not the main actor. They are handled by `CameraFrameProcessor` /
//  `PhotoCaptureProcessor` — plain (non-actor) classes that guard their shared
//  "look" state with a lock — and hop back to the main actor only to publish
//  results. This keeps the view model clean under Swift 6 strict concurrency.
//

import AVFoundation
import CoreImage
import SwiftUI

@MainActor
final class CameraViewModel: NSObject, ObservableObject {

    // MARK: Published UI state
    @Published var previewImage: CGImage?          // live filtered frame
    @Published var isSessionRunning = false
    @Published var permissionDenied = false
    @Published var isCapturing = false
    @Published var flashScreen = false             // white shutter flash overlay
    @Published var cameraPosition: AVCaptureDevice.Position = .back
    @Published var torchOn = false

    /// The currently selected look. didSet pushes it down to the frame/photo
    /// processors so off-main rendering always uses the latest values.
    @Published var stock: FilmStock = .kodakGold {
        didSet { syncLook() }
    }
    @Published var settings: FilterSettings = .default {
        didSet { syncLook() }
    }

    /// Fired (on the main actor) with the finished capture: (original, rendered).
    var onPhotoCaptured: ((UIImage, UIImage) -> Void)?

    // MARK: AV plumbing
    private let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "com.retrofilm.session")
    private let videoQueue = DispatchQueue(label: "com.retrofilm.video")
    private let videoOutput = AVCaptureVideoDataOutput()
    private let photoOutput = AVCapturePhotoOutput()
    private var videoDeviceInput: AVCaptureDeviceInput?

    private let frameProcessor = CameraFrameProcessor()
    private var photoProcessor: PhotoCaptureProcessor?

    override init() {
        super.init()
        frameProcessor.onFrame = { [weak self] cg in
            Task { @MainActor in self?.previewImage = cg }
        }
        syncLook()
    }

    /// Mirrors the current look into the off-main processors.
    private func syncLook() {
        frameProcessor.update(stock: stock, settings: settings)
    }

    // MARK: - Lifecycle

    /// Requests permission and configures the session. Safe to call repeatedly.
    func start() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            configureAndRun()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                Task { @MainActor in
                    if granted { self?.configureAndRun() } else { self?.permissionDenied = true }
                }
            }
        default:
            permissionDenied = true
        }
    }

    func stop() {
        sessionQueue.async { [session] in
            if session.isRunning { session.stopRunning() }
        }
    }

    private func configureAndRun() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            self.configureSession()
            if !self.session.isRunning { self.session.startRunning() }
            let running = self.session.isRunning
            Task { @MainActor in self.isSessionRunning = running }
        }
    }

    /// One-time session graph setup. Runs on the session queue.
    private func configureSession() {
        guard videoDeviceInput == nil else { return }   // already configured

        session.beginConfiguration()
        session.sessionPreset = .photo

        if let device = bestCamera(for: cameraPosition),
           let input = try? AVCaptureDeviceInput(device: device),
           session.canAddInput(input) {
            session.addInput(input)
            videoDeviceInput = input
        }

        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.setSampleBufferDelegate(frameProcessor, queue: videoQueue)
        if session.canAddOutput(videoOutput) { session.addOutput(videoOutput) }

        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
            photoOutput.maxPhotoQualityPrioritization = .quality
        }

        session.commitConfiguration()
    }

    private func bestCamera(for position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        let types: [AVCaptureDevice.DeviceType] = [.builtInDualCamera, .builtInWideAngleCamera]
        return AVCaptureDevice.DiscoverySession(deviceTypes: types, mediaType: .video, position: position)
            .devices.first
    }

    // MARK: - Controls

    func switchCamera() {
        cameraPosition = (cameraPosition == .back) ? .front : .back
        let newPosition = cameraPosition
        frameProcessor.setFrontCamera(newPosition == .front)
        sessionQueue.async { [weak self] in
            guard let self, let current = self.videoDeviceInput else { return }
            self.session.beginConfiguration()
            self.session.removeInput(current)
            if let device = self.bestCamera(for: newPosition),
               let input = try? AVCaptureDeviceInput(device: device),
               self.session.canAddInput(input) {
                self.session.addInput(input)
                self.videoDeviceInput = input
            } else {
                self.session.addInput(current)   // restore on failure
            }
            self.session.commitConfiguration()
        }
    }

    func toggleTorch() {
        guard cameraPosition == .back,
              let device = videoDeviceInput?.device, device.hasTorch else { return }
        torchOn.toggle()
        let on = torchOn
        sessionQueue.async {
            guard (try? device.lockForConfiguration()) != nil else { return }
            device.torchMode = on ? .on : .off
            device.unlockForConfiguration()
        }
    }

    /// Tap-to-focus at a normalized device point (0...1).
    func focus(at point: CGPoint) {
        sessionQueue.async { [weak self] in
            guard let device = self?.videoDeviceInput?.device,
                  (try? device.lockForConfiguration()) != nil else { return }
            if device.isFocusPointOfInterestSupported {
                device.focusPointOfInterest = point
                device.focusMode = .autoFocus
            }
            if device.isExposurePointOfInterestSupported {
                device.exposurePointOfInterest = point
                device.exposureMode = .continuousAutoExposure
            }
            device.unlockForConfiguration()
        }
    }

    // MARK: - Capture

    func capturePhoto() {
        guard !isCapturing else { return }
        isCapturing = true
        HapticManager.shutter()
        withAnimation(.easeOut(duration: 0.08)) { flashScreen = true }

        let position = cameraPosition
        let look = (stock, settings)

        // Build a retained processor that renders then calls us back on main.
        let processor = PhotoCaptureProcessor(stock: look.0, settings: look.1) { [weak self] original, rendered in
            Task { @MainActor in
                guard let self else { return }
                withAnimation(.easeIn(duration: 0.2)) { self.flashScreen = false }
                self.isCapturing = false
                self.photoProcessor = nil
                if let original, let rendered {
                    HapticManager.success()
                    self.onPhotoCaptured?(original, rendered)
                } else {
                    HapticManager.warning()
                }
            }
        }
        photoProcessor = processor

        sessionQueue.async { [weak self] in
            guard let self else { return }
            let settings = AVCapturePhotoSettings()
            settings.photoQualityPrioritization = .quality
            if let connection = self.photoOutput.connection(with: .video) {
                if connection.isVideoRotationAngleSupported(90) { connection.videoRotationAngle = 90 }
                if position == .front, connection.isVideoMirroringSupported {
                    connection.automaticallyAdjustsVideoMirroring = false
                    connection.isVideoMirrored = true
                }
            }
            self.photoOutput.capturePhoto(with: settings, delegate: processor)
        }
    }
}

// MARK: - Live frame processor (off the main actor)

/// Receives video frames on the video queue, renders the film look at preview
/// quality, and calls `onFrame` with a CGImage. Look state is lock-guarded so
/// the main actor can update it concurrently. `@unchecked Sendable` is sound
/// because every mutable field is accessed only under `lock`.
final class CameraFrameProcessor: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, @unchecked Sendable {

    var onFrame: ((CGImage) -> Void)?

    private let lock = NSLock()
    private var stock: FilmStock = .kodakGold
    private var settings: FilterSettings = .default
    private var isFrontCamera = false
    private let engine = FilmFilterEngine.shared

    func update(stock: FilmStock, settings: FilterSettings) {
        lock.lock(); self.stock = stock; self.settings = settings; lock.unlock()
    }

    func setFrontCamera(_ isFront: Bool) {
        lock.lock(); self.isFrontCamera = isFront; lock.unlock()
    }

    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        lock.lock(); let stock = self.stock; let settings = self.settings; let isFront = self.isFrontCamera; lock.unlock()

        var ciImage = CIImage(cvPixelBuffer: pixelBuffer).oriented(.right)   // portrait
        if isFront {
            ciImage = ciImage
                .transformed(by: CGAffineTransform(scaleX: -1, y: 1))
                .transformed(by: CGAffineTransform(translationX: ciImage.extent.width, y: 0))
        }

        guard let cg = engine.render(ciImage, stock: stock, settings: settings, quality: .preview) else { return }
        onFrame?(cg)
    }
}

// MARK: - Photo capture processor (off the main actor)

/// Handles a single high-resolution capture: decodes the still, renders it at
/// export quality, and reports `(original, rendered)` via `completion`. Held
/// alive by the view model until the callback fires.
final class PhotoCaptureProcessor: NSObject, AVCapturePhotoCaptureDelegate, @unchecked Sendable {

    private let stock: FilmStock
    private let settings: FilterSettings
    private let completion: (UIImage?, UIImage?) -> Void

    init(stock: FilmStock, settings: FilterSettings, completion: @escaping (UIImage?, UIImage?) -> Void) {
        self.stock = stock
        self.settings = settings
        self.completion = completion
    }

    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {
        guard error == nil,
              let data = photo.fileDataRepresentation(),
              let original = UIImage(data: data) else {
            completion(nil, nil)
            return
        }
        let rendered = FilmFilterEngine.shared.renderUIImage(original, stock: stock, settings: settings, quality: .export)
        completion(original, rendered ?? original)
    }
}
