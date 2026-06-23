//
//  ScanWorkflowViewModel.swift
//  DocScanPro
//
//  扫描流程 ViewModel：接收扫描相机产出的图像，
//  落库为 ScanDocument + ScannedPage，并按需触发本地 OCR。
//

import Foundation
import SwiftData
import SwiftUI

@MainActor
final class ScanWorkflowViewModel: ObservableObject {

    /// OCR 处理进度（0...1），nil 表示未在处理。
    @Published var ocrProgress: Double?

    /// 处理中的状态文案。
    @Published var statusMessage: String?

    /// 错误信息。
    @Published var errorMessage: String?

    private let ocrService = OCRService.shared

    /// 将扫描得到的图像保存为新文档。
    /// - Parameters:
    ///   - images: 扫描相机返回的页面图像。
    ///   - context: SwiftData 上下文。
    ///   - folder: 可选归属文件夹。
    ///   - runOCR: 是否在保存后执行 OCR（取决于设置与权益）。
    ///   - jpegQuality: 图像压缩质量。
    /// - Returns: 新建的文档。
    @discardableResult
    func saveScannedImages(
        _ images: [UIImage],
        context: ModelContext,
        folder: Folder?,
        runOCR: Bool,
        jpegQuality: Double
    ) async -> ScanDocument? {
        guard !images.isEmpty else { return nil }

        let document = ScanDocument(title: defaultTitle())
        document.folder = folder

        var pages: [ScannedPage] = []
        for (index, image) in images.enumerated() {
            guard let data = image.compressedJPEGData(quality: jpegQuality) else { continue }
            let page = ScannedPage(imageData: data, order: index)
            page.document = document
            pages.append(page)
            context.insert(page)
        }
        document.pages = pages
        context.insert(document)

        do {
            try context.save()
        } catch {
            errorMessage = error.localizedDescription
            Haptics.error()
            return nil
        }

        if runOCR {
            // 用 self. 显式指向方法，避免与同名 Bool 参数 `runOCR` 的命名遮蔽。
            await self.runOCR(on: document, context: context)
        }

        return document
    }

    /// 对文档的所有页面执行本地 OCR，并写回识别文本。
    func runOCR(on document: ScanDocument, context: ModelContext) async {
        let pages = document.orderedPages
        guard !pages.isEmpty else { return }

        ocrProgress = 0
        statusMessage = NSLocalizedString("scan.ocr.processing", comment: "")
        defer {
            ocrProgress = nil
            statusMessage = nil
        }

        for (index, page) in pages.enumerated() {
            do {
                let result = try await ocrService.recognizeText(in: page.imageData)
                page.recognizedText = result.text
                page.isOCRProcessed = true
            } catch {
                // OCR 为尽力而为的便捷功能：单页失败不阻断整体流程，
                // 也不弹出阻断式错误（扫描已成功保存，用户可在详情页重跑 OCR）。
                // 失败页保持 isOCRProcessed = false，以便与「已识别但无文字」区分、支持后续重试。
                page.isOCRProcessed = false
            }
            ocrProgress = Double(index + 1) / Double(pages.count)
        }

        document.updatedAt = .now
        try? context.save()
    }

    /// 以当前时间生成默认文档标题。
    private func defaultTitle() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        let prefix = NSLocalizedString("scan.defaultTitle.prefix", comment: "扫描")
        return "\(prefix) \(formatter.string(from: .now))"
    }
}
