//
//  PhotoEditViewModel.swift
//  RetroFilm
//
//  Drives the re-edit ("二次滤镜") screen: holds the editable look, re-renders
//  the original image off the main thread (debounced), and exports the result
//  to the system Photos library.
//

import SwiftUI
import Photos

@MainActor
final class PhotoEditViewModel: ObservableObject {

    @Published var stock: FilmStock
    @Published var settings: FilterSettings
    @Published var preview: UIImage?
    @Published var isRendering = false
    @Published var exportMessage: String?

    private let original: UIImage
    private let createdAt: Date
    private let engine = FilmFilterEngine.shared
    private var renderTask: Task<Void, Never>?

    init(photo: CapturedPhoto) {
        self.stock = photo.filmStock
        self.settings = photo.settings
        self.createdAt = photo.createdAt
        // Load the pristine original so re-edits are non-destructive.
        self.original = PhotoStorage.shared.load(photo.originalFileName)
            ?? PhotoStorage.shared.load(photo.renderedFileName)
            ?? UIImage()
    }

    /// Renders the current look, debounced so rapid slider drags don't pile up.
    func scheduleRender() {
        renderTask?.cancel()
        let stock = self.stock
        let settings = self.settings
        let source = self.original
        let date = self.createdAt
        isRendering = true
        renderTask = Task { [weak self] in
            // Small debounce window.
            try? await Task.sleep(nanoseconds: 90_000_000)
            if Task.isCancelled { return }
            let result = await Task.detached(priority: .userInitiated) {
                FilmFilterEngine.shared.renderUIImage(source, stock: stock, settings: settings, quality: .export, date: date)
            }.value
            if Task.isCancelled { return }
            await MainActor.run {
                self?.preview = result
                self?.isRendering = false
            }
        }
    }

    /// Persists the re-edited render back into the library record + disk.
    func saveEdits(to photo: CapturedPhoto, context: ModelContextBox) {
        guard let rendered = preview else { return }
        do {
            let files = try PhotoStorage.shared.updateRender(rendered, id: photo.id)
            photo.filmStockID = stock.id
            photo.settingsData = (try? JSONEncoder().encode(settings)) ?? photo.settingsData
            photo.renderedFileName = files.rendered
            photo.thumbnailFileName = files.thumbnail
            context.save()
            HapticManager.success()
        } catch {
            HapticManager.warning()
        }
    }

    /// Exports the current render to the user's Photos library, requesting
    /// permission if needed.
    func exportToPhotos() {
        guard let image = preview else { return }
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { [weak self] status in
            guard status == .authorized || status == .limited else {
                Task { @MainActor in self?.exportMessage = NSLocalizedString("export.denied", comment: "") }
                return
            }
            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            } completionHandler: { success, _ in
                Task { @MainActor in
                    self?.exportMessage = success
                        ? NSLocalizedString("export.success", comment: "")
                        : NSLocalizedString("export.failed", comment: "")
                    if success { HapticManager.success() }
                }
            }
        }
    }
}

/// Tiny wrapper so the view model can save without importing SwiftData's
/// `ModelContext` directly into its public API (keeps it testable).
struct ModelContextBox {
    let save: () -> Void
}
