//
//  EditorViewModel.swift
//  ShotFrame
//
//  Owns the mutable editing state for a single `ShotProject`. Holds the
//  decoded images in memory (so the canvas re-renders instantly) and writes
//  changes back into SwiftData. Views bind to `settings` directly.
//

import SwiftUI
import SwiftData

@MainActor
final class EditorViewModel: ObservableObject {

    let project: ShotProject
    private let context: ModelContext

    /// The live editing recipe. Mutating this updates the preview immediately;
    /// `persist()` flushes it to the stored model.
    @Published var settings: ShotSettings {
        didSet { schedulePersist() }
    }

    @Published private(set) var sourceImage: UIImage?
    @Published private(set) var backgroundImage: UIImage?

    /// The annotation currently being manipulated (drag / text edit), if any.
    @Published var selectedAnnotationID: UUID?

    // Export / save state surfaced to the UI.
    @Published var isExporting = false
    @Published var statusMessage: String?
    @Published var errorMessage: String?

    private var persistTask: Task<Void, Never>?

    init(project: ShotProject, context: ModelContext) {
        self.project = project
        self.context = context
        self.settings = project.settings
        self.sourceImage = project.sourceImage
        self.backgroundImage = project.backgroundImage
    }

    // MARK: - Persistence

    /// Debounced save so dragging a slider doesn't hammer the store. The Task is
    /// created in a `@MainActor` context, so it runs `persist()` on the main actor.
    private func schedulePersist() {
        persistTask?.cancel()
        persistTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(400))
            guard let self, !Task.isCancelled else { return }
            self.persist()
        }
    }

    func persist() {
        project.settings = settings
        project.touch()
        try? context.save()
    }

    // MARK: - Templates

    /// Apply a template's styling while keeping the user's annotations.
    /// Returns false if the template is Pro and the user hasn't unlocked it.
    @discardableResult
    func apply(template: ShotTemplate, isPro: Bool) -> Bool {
        guard !template.isPro || isPro else { return false }
        var new = template.settings
        new.annotations = settings.annotations
        settings = new
        Haptics.selection()
        return true
    }

    // MARK: - Background image

    func setBackgroundImage(_ image: UIImage?) {
        backgroundImage = image
        project.backgroundImageData = image?.jpegData(compressionQuality: 0.9)
        if image != nil { settings.background.kind = .image }
        persist()
    }

    // MARK: - Annotations

    func addAnnotation() {
        var annotation = Annotation()
        annotation.text = NSLocalizedString("annotation.placeholder", comment: "")
        settings.annotations.append(annotation)
        selectedAnnotationID = annotation.id
        Haptics.tap()
    }

    func removeSelectedAnnotation() {
        guard let id = selectedAnnotationID else { return }
        settings.annotations.removeAll { $0.id == id }
        selectedAnnotationID = settings.annotations.last?.id
        Haptics.tap()
    }

    /// Binding to the currently selected annotation, for the text inspector.
    /// Looks the annotation up by id on every access so it stays valid even if
    /// the array is mutated elsewhere.
    var selectedAnnotation: Binding<Annotation>? {
        guard let id = selectedAnnotationID,
              settings.annotations.contains(where: { $0.id == id })
        else { return nil }
        return Binding(
            get: {
                self.settings.annotations.first(where: { $0.id == id }) ?? Annotation()
            },
            set: { newValue in
                if let index = self.settings.annotations.firstIndex(where: { $0.id == id }) {
                    self.settings.annotations[index] = newValue
                }
            }
        )
    }

    /// Move the selected annotation to a normalized canvas position (clamped).
    func moveSelectedAnnotation(to point: CGPoint) {
        guard let id = selectedAnnotationID,
              let index = settings.annotations.firstIndex(where: { $0.id == id })
        else { return }
        settings.annotations[index].position = CGPoint(
            x: Double(point.x).clamped(to: 0...1),
            y: Double(point.y).clamped(to: 0...1)
        )
    }

    // MARK: - Export

    /// Render the finished image at the requested resolution.
    func renderImage(resolution: ExportResolution, watermark: Bool) -> UIImage? {
        CanvasRenderer.render(
            image: sourceImage,
            backgroundImage: backgroundImage,
            settings: settings,
            resolution: resolution,
            watermark: watermark
        )
    }

    /// Render and save to the photo library, surfacing status to the UI.
    func saveToPhotos(resolution: ExportResolution, watermark: Bool) async {
        isExporting = true
        defer { isExporting = false }

        guard let image = renderImage(resolution: resolution, watermark: watermark) else {
            errorMessage = NSLocalizedString("error.render", comment: "")
            Haptics.warning()
            return
        }
        do {
            try await PhotoLibrary.save(image)
            statusMessage = NSLocalizedString("export.saved", comment: "")
            Haptics.success()
        } catch {
            errorMessage = error.localizedDescription
            Haptics.warning()
        }
    }
}
