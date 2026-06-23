//
//  PDFExporter.swift
//  DocScanPro
//
//  将扫描文档导出为 PDF，基于 PDFKit / UIGraphicsPDFRenderer。
//  可选将 OCR 文本作为不可见图层嵌入，使生成的 PDF 可被全文搜索与复制。
//  全程本地处理，不上传。
//

import Foundation
import PDFKit
import UIKit

enum PDFExportError: LocalizedError {
    case noPages
    case renderFailed

    var errorDescription: String? {
        switch self {
        case .noPages:
            return NSLocalizedString("pdf.error.noPages", comment: "文档没有可导出的页面")
        case .renderFailed:
            return NSLocalizedString("pdf.error.renderFailed", comment: "PDF 生成失败")
        }
    }
}

struct PDFExporter {

    /// A4 尺寸（72 dpi，单位 point）。
    static let a4Size = CGSize(width: 595.2, height: 841.8)

    /// 将一组页面渲染为 PDF 数据。
    /// - Parameters:
    ///   - pages: 已排序的扫描页面。
    ///   - includeTextLayer: 是否嵌入可搜索文本层。
    /// - Returns: PDF 二进制数据。
    static func makePDF(from pages: [ScannedPage], includeTextLayer: Bool = true) throws -> Data {
        guard !pages.isEmpty else { throw PDFExportError.noPages }

        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: a4Size))

        let data = renderer.pdfData { context in
            for page in pages {
                guard let image = UIImage(data: page.imageData) else { continue }
                context.beginPage()

                // 等比缩放图像以适配页面，居中绘制。
                let pageRect = CGRect(origin: .zero, size: a4Size)
                let drawRect = aspectFitRect(for: image.size, in: pageRect)
                image.draw(in: drawRect)

                // 以接近透明的方式绘制 OCR 文本，使 PDF 可搜索而不影响视觉。
                if includeTextLayer, !page.recognizedText.isEmpty {
                    drawSearchableText(page.recognizedText, in: pageRect)
                }
            }
        }

        guard !data.isEmpty else { throw PDFExportError.renderFailed }
        return data
    }

    /// 将 PDF 数据写入临时目录，返回可用于分享的文件 URL。
    /// 每次导出写入独立子目录，避免同名文档相互覆盖；文件名清理非法字符。
    static func writeTemporaryPDF(_ data: Data, fileName: String) throws -> URL {
        let illegal = CharacterSet(charactersIn: "/\\:?%*|\"<>").union(.controlCharacters)
        let cleaned = fileName
            .components(separatedBy: illegal)
            .joined(separator: "-")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let safeName = cleaned.isEmpty ? "Document" : cleaned

        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("PDFExport-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let url = directory
            .appendingPathComponent(safeName)
            .appendingPathExtension("pdf")
        try data.write(to: url, options: .atomic)
        return url
    }

    // MARK: - Private helpers

    /// 计算图像在目标矩形内等比适配（aspect fit）后的绘制区域。
    private static func aspectFitRect(for imageSize: CGSize, in bounds: CGRect) -> CGRect {
        guard imageSize.width > 0, imageSize.height > 0 else { return bounds }
        let scale = min(bounds.width / imageSize.width, bounds.height / imageSize.height)
        let scaledSize = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
        let origin = CGPoint(
            x: bounds.midX - scaledSize.width / 2,
            y: bounds.midY - scaledSize.height / 2
        )
        return CGRect(origin: origin, size: scaledSize)
    }

    /// 以极低不透明度绘制文本层，使 PDF 文本可选中 / 可搜索。
    /// 文本层不可见，「能放下全部文字」比「易读」更重要：因此自适应缩小字号，
    /// 直到整段 OCR 文本在可绘制区域内不被裁剪（`draw(in:)` 会静默截断溢出内容）。
    private static func drawSearchableText(_ text: String, in rect: CGRect) {
        let inset = rect.insetBy(dx: 18, dy: 18)
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = .byWordWrapping

        // 从常规字号逐步缩小，直到文本高度可容纳于绘制区域内。
        let maxFontSize: CGFloat = 11
        let minFontSize: CGFloat = 4
        var fontSize = maxFontSize
        var attributes: [NSAttributedString.Key: Any] = [:]

        while fontSize >= minFontSize {
            attributes = [
                .font: UIFont.systemFont(ofSize: fontSize),
                // 几乎不可见，但仍被 PDFKit 索引为可选中文本。
                .foregroundColor: UIColor.black.withAlphaComponent(0.01),
                .paragraphStyle: paragraph
            ]
            let bounding = (text as NSString).boundingRect(
                with: CGSize(width: inset.width, height: .greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: attributes,
                context: nil
            )
            if bounding.height <= inset.height { break }
            fontSize -= 1
        }

        (text as NSString).draw(in: inset, withAttributes: attributes)
    }
}
