//
//  PreviewData.swift
//  DocScanPro
//
//  仅供 SwiftUI #Preview 使用的内存数据容器与示例数据。
//  使用 in-memory 配置，不写入磁盘。
//

import SwiftData
import SwiftUI
import UIKit

enum PreviewData {

    /// 内存型预览容器，预置示例文档、文件夹与标签。
    @MainActor static let container: ModelContainer = {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(
            for: ScanDocument.self, ScannedPage.self, Folder.self, Tag.self,
            configurations: configuration
        )

        let context = container.mainContext

        let folder = Folder(name: "工作合同", symbolName: "briefcase.fill")
        context.insert(folder)

        let tag = Tag(name: "重要", colorHex: "#FF6B6B")
        context.insert(tag)

        let document = makeSampleDocument()
        document.folder = folder
        document.tags = [tag]
        context.insert(document)

        try? context.save()
        return container
    }()

    /// 便捷访问的示例文档（用于详情/结果预览）。
    @MainActor static var sampleDocument: ScanDocument {
        let descriptor = FetchDescriptor<ScanDocument>()
        return (try? container.mainContext.fetch(descriptor).first) ?? makeSampleDocument()
    }

    /// 构造一个带占位图与示例 OCR 文本的文档。
    @MainActor static func makeSampleDocument() -> ScanDocument {
        let document = ScanDocument(title: "示例扫描文档")
        let page = ScannedPage(
            imageData: placeholderImageData(),
            recognizedText: "DocScanPro 端侧 OCR 文档扫描仪\n\n本页文字由设备本地 Vision 框架识别，\n全程不联网、不上传云端。\n\nThis text was recognized entirely on-device.",
            order: 0,
            isOCRProcessed: true
        )
        page.document = document
        document.pages = [page]
        return document
    }

    /// 生成一张纯色占位图作为页面缩略图。
    private static func placeholderImageData() -> Data {
        let size = CGSize(width: 400, height: 560)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            UIColor.systemGray5.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
            let text = "DocScanPro" as NSString
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 28),
                .foregroundColor: UIColor.systemGray
            ]
            let textSize = text.size(withAttributes: attrs)
            text.draw(
                at: CGPoint(x: (size.width - textSize.width) / 2, y: (size.height - textSize.height) / 2),
                withAttributes: attrs
            )
        }
        return image.jpegData(compressionQuality: 0.8) ?? Data()
    }
}
