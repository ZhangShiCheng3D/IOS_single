//
//  EditorViewModel.swift
//  CollageKit
//
//  编辑器视图模型：负责照片导入/替换/交换、文字增删、导出合成与保存到相册。
//  SwiftData 模型的简单属性编辑由视图层通过 @Bindable 直接完成，
//  这里集中处理涉及图片解码、渲染等较重的业务逻辑。
//

import SwiftUI
import SwiftData
import PhotosUI

@MainActor
final class EditorViewModel: ObservableObject {

    /// 已解码图片缓存，键为插槽序号，供实时预览复用，避免每帧解码。
    @Published private(set) var imageCache: [Int: UIImage] = [:]
    @Published var selectedSlotIndex: Int?
    @Published var selectedTextID: UUID?

    @Published var isExporting = false
    @Published var exportedImage: UIImage?
    @Published var statusMessage: String?
    @Published var showSavedToast = false

    private let saver = PhotoSaver()

    // MARK: - 生命周期

    /// 预热缓存：把工程内已有照片解码备用。
    func prepare(project: CollageProject) {
        for photo in project.photos where imageCache[photo.slotIndex] == nil {
            if let image = ImageUtils.image(from: photo.imageData) {
                imageCache[photo.slotIndex] = image
            }
        }
    }

    /// 只读取图片用于显示，不写入缓存（可安全在视图 body 中调用）。
    /// 缓存由 `prepare` / `setPhoto` / `swapSlots` 维护。
    func cachedImage(forSlot index: Int, in project: CollageProject) -> UIImage? {
        if let cached = imageCache[index] { return cached }
        guard let photo = project.photo(forSlot: index) else { return nil }
        return ImageUtils.image(from: photo.imageData)
    }

    // MARK: - 照片导入

    /// 把 PhotosPicker 选中的图片放入指定插槽。
    func setPhoto(_ pickerItem: PhotosPickerItem,
                  slotIndex: Int,
                  project: CollageProject,
                  context: ModelContext) async {
        guard let data = try? await pickerItem.loadTransferable(type: Data.self),
              let uiImage = UIImage(data: data) else {
            statusMessage = String(localized: "error_load_photo")
            return
        }
        setPhoto(uiImage, slotIndex: slotIndex, project: project, context: context)
    }

    /// 把一张 UIImage 放入插槽（降采样后持久化）。
    func setPhoto(_ uiImage: UIImage,
                  slotIndex: Int,
                  project: CollageProject,
                  context: ModelContext) {
        guard let jpeg = ImageUtils.downsampledJPEGData(from: uiImage) else {
            statusMessage = String(localized: "error_load_photo")
            return
        }

        if let existing = project.photo(forSlot: slotIndex) {
            existing.imageData = jpeg
            existing.scale = 1
            existing.offsetX = 0
            existing.offsetY = 0
        } else {
            let photo = CollagePhoto(slotIndex: slotIndex, imageData: jpeg)
            photo.project = project
            project.photos.append(photo)
            context.insert(photo)
        }
        imageCache[slotIndex] = ImageUtils.downsample(uiImage, maxDimension: 1600)
        project.touch()
    }

    /// 清空某个插槽的照片。
    func clearSlot(_ index: Int, project: CollageProject, context: ModelContext) {
        if let photo = project.photo(forSlot: index) {
            project.photos.removeAll { $0.id == photo.id }
            context.delete(photo)
        }
        imageCache[index] = nil
        project.touch()
    }

    /// 切换模板：清理超出新插槽数量的照片并同步缓存，再更新模板。
    func applyTemplateChange(to project: CollageProject,
                             template: CollageTemplate,
                             context: ModelContext) {
        let newCount = template.slotCount
        let removed = project.photos.filter { $0.slotIndex >= newCount }
        for photo in removed {
            project.photos.removeAll { $0.id == photo.id }
            context.delete(photo)
            imageCache[photo.slotIndex] = nil
        }
        project.templateID = template.id
        project.touch()
        selectedSlotIndex = nil
    }

    /// 拖拽替换：交换两个插槽里的照片（含外观调整）。
    func swapSlots(_ a: Int, _ b: Int, project: CollageProject) {
        guard a != b else { return }
        let pa = project.photo(forSlot: a)
        let pb = project.photo(forSlot: b)

        pa?.slotIndex = b
        pb?.slotIndex = a

        let ia = imageCache[a]
        imageCache[a] = imageCache[b]
        imageCache[b] = ia

        project.touch()
    }

    // MARK: - 文字

    @discardableResult
    func addText(_ content: String, project: CollageProject, context: ModelContext) -> CollageText {
        let text = CollageText(content: content)
        text.project = project
        project.texts.append(text)
        context.insert(text)
        selectedTextID = text.id
        project.touch()
        return text
    }

    func deleteText(_ text: CollageText, project: CollageProject, context: ModelContext) {
        project.texts.removeAll { $0.id == text.id }
        context.delete(text)
        if selectedTextID == text.id { selectedTextID = nil }
        project.touch()
    }

    // MARK: - 导出

    /// 渲染工程为图片（用于预览/分享/保存）。
    func render(project: CollageProject, isPro: Bool) -> UIImage {
        prepare(project: project)
        var renderer = CollageRenderer()
        renderer.addWatermark = !isPro
        return renderer.render(project: project, loadedImages: imageCache)
    }

    /// 渲染并保存到相册。
    func exportToAlbum(project: CollageProject, isPro: Bool) async {
        isExporting = true
        defer { isExporting = false }
        let image = render(project: project, isPro: isPro)
        do {
            try await saver.save(image)
            showSavedToast = true
        } catch {
            statusMessage = error.localizedDescription
        }
    }
}
