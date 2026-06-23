//
//  CameraManager.swift
//  SeniorHelper
//
//  放大镜摄像头会话管理：实时预览、缩放、手电筒。
//

import Foundation
import AVFoundation
import Observation
import UIKit

/// 管理 AVCaptureSession，提供给放大镜的实时画面、变焦与手电筒控制。
@Observable
final class CameraManager: NSObject {

    /// 摄像头授权状态。
    private(set) var authorizationStatus: AVAuthorizationStatus = .notDetermined

    /// 会话是否正在运行。
    private(set) var isRunning = false

    /// 手电筒是否点亮。
    private(set) var isTorchOn = false

    /// 当前缩放倍数（1.0 ~ maxZoom）。
    var zoomFactor: CGFloat = 1.0 {
        didSet { applyZoom() }
    }

    /// 设备支持的最大可用缩放倍数（封顶以避免画质过差）。
    private(set) var maxZoom: CGFloat = 5.0

    /// 暴露给预览层的会话对象。
    let session = AVCaptureSession()

    private let sessionQueue = DispatchQueue(label: "SeniorHelper.camera.session")
    private var device: AVCaptureDevice?

    override init() {
        super.init()
        authorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
    }

    /// 申请摄像头权限。
    @discardableResult
    func requestAuthorization() async -> Bool {
        let granted = await AVCaptureDevice.requestAccess(for: .video)
        await MainActor.run {
            authorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
        }
        return granted
    }

    /// 配置并启动会话。须在已获授权后调用。
    func start() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            if self.session.inputs.isEmpty {
                self.configureSession()
            }
            if !self.session.isRunning {
                self.session.startRunning()
                DispatchQueue.main.async { self.isRunning = self.session.isRunning }
            }
        }
    }

    /// 停止会话并关闭手电筒。
    func stop() {
        setTorch(on: false)
        sessionQueue.async { [weak self] in
            guard let self else { return }
            if self.session.isRunning {
                self.session.stopRunning()
                DispatchQueue.main.async { self.isRunning = false }
            }
        }
    }

    /// 切换手电筒。
    func toggleTorch() {
        setTorch(on: !isTorchOn)
    }

    /// 设置手电筒状态。
    func setTorch(on: Bool) {
        guard let device, device.hasTorch, device.isTorchAvailable else { return }
        do {
            try device.lockForConfiguration()
            if on {
                try device.setTorchModeOn(level: 1.0)
            } else {
                device.torchMode = .off
            }
            device.unlockForConfiguration()
            DispatchQueue.main.async { self.isTorchOn = on }
        } catch {
            print("切换手电筒失败: \(error.localizedDescription)")
        }
    }

    // MARK: - Private

    private func configureSession() {
        session.beginConfiguration()
        session.sessionPreset = .high

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else {
            session.commitConfiguration()
            print("无法配置摄像头输入")
            return
        }

        session.addInput(input)
        self.device = device

        // 计算安全的最大缩放（封顶 8 倍，避免数码放大过度模糊）。
        let deviceMax = device.activeFormat.videoMaxZoomFactor
        DispatchQueue.main.async {
            self.maxZoom = min(deviceMax, 8.0)
        }

        session.commitConfiguration()
    }

    private func applyZoom() {
        sessionQueue.async { [weak self] in
            guard let self, let device = self.device else { return }
            do {
                try device.lockForConfiguration()
                let clamped = max(1.0, min(self.zoomFactor, device.activeFormat.videoMaxZoomFactor))
                device.videoZoomFactor = clamped
                device.unlockForConfiguration()
            } catch {
                print("设置缩放失败: \(error.localizedDescription)")
            }
        }
    }
}
