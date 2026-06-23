//
//  DocumentDetailViewModel.swift
//  DocScanPro
//
//  文档详情 ViewModel：负责 PDF 导出、OCR 重跑、页面与文档维护。
//

import Foundation
import SwiftData
import SwiftUI

@MainActor
final class DocumentDetailViewModel: ObservableObject {

    /// 待分享的 PDF 文件 URL。
    @Published var shareURL: URL?

    /// 是否正在导出 / 处理。
    @Published var isExporting = false

    /// 错误信息。
    @Published var errorMessage: String?

    /// OCR 重跑进度。
    @Published var ocrProgress: Double?

    private let ocrService = OCRService.shared

    /// 导出文档为 PDF，并准备分享 URL。
    func exportPDF(for document: ScanDocument, includeTextLayer: Bool) async {
        isExporting = true
        defer { isExporting = false }
        do {
            let data = try PDFExporter.makePDF(
                from: document.orderedPages,
                includeTextLayer: includeTextLayer
            )
            let url = try PDFExporter.writeTemporaryPDF(data, fileName: document.title)
            shareURL = url
            Haptics.success()
        } catch {
            errorMessage = error.localizedDescription
            Haptics.error()
        }
    }

    /// 对文档重新执行本地 OCR。
    func rerunOCR(for document: ScanDocument, context: ModelContext) async {
        let pages = document.orderedPages
        guard !pages.isEmpty else { return }

        ocrProgress = 0
        defer { ocrProgress = nil }

        for (index, page) in pages.enumerated() {
            if let result = try? await ocrService.recognizeText(in: page.imageData) {
                page.recognizedText = result.text
                page.isOCRProcessed = true
            }
            ocrProgress = Double(index + 1) / Double(pages.count)
        }
        document.updatedAt = .now
        try? context.save()
        Haptics.success()
    }

    /// 删除指定页面。
    func deletePage(_ page: ScannedPage, from document: ScanDocument, context: ModelContext) {
        context.delete(page)
        // 重排剩余页面序号，保持连续。
        for (index, remaining) in document.orderedPages.enumerated() {
            remaining.order = index
        }
        document.updatedAt = .now
        try? context.save()
    }

    /// 重命名文档。
    func rename(_ document: ScanDocument, to newTitle: String, context: ModelContext) {
        let trimmed = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        document.title = trimmed
        document.updatedAt = .now
        try? context.save()
    }

    /// 更新单页的 OCR 文本（用户手动编辑后保存）。
    func updateText(_ text: String, for page: ScannedPage, in document: ScanDocument, context: ModelContext) {
        page.recognizedText = text
        document.updatedAt = .now
        try? context.save()
    }
}
