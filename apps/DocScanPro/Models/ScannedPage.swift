//
//  ScannedPage.swift
//  DocScanPro
//
//  单页扫描结果。存储校正后的图像数据（JPEG）与本地 OCR 识别出的文本。
//  图像以二进制存于本地数据库，永不离开设备。
//

import Foundation
import SwiftData

@Model
final class ScannedPage {

    @Attribute(.unique) var id: UUID

    /// 透视校正后的页面图像（JPEG 编码）。使用 externalStorage
    /// 让 SwiftData 将大二进制存到独立文件，保持数据库轻量。
    @Attribute(.externalStorage) var imageData: Data

    /// 本地 OCR 识别出的纯文本，用户可编辑覆盖。
    var recognizedText: String

    /// 页码顺序（从 0 开始）。
    var order: Int

    /// OCR 是否已执行完毕。
    var isOCRProcessed: Bool

    var createdAt: Date

    /// 反向关系：所属文档。
    var document: ScanDocument?

    init(
        id: UUID = UUID(),
        imageData: Data,
        recognizedText: String = "",
        order: Int,
        isOCRProcessed: Bool = false,
        createdAt: Date = .now,
        document: ScanDocument? = nil
    ) {
        self.id = id
        self.imageData = imageData
        self.recognizedText = recognizedText
        self.order = order
        self.isOCRProcessed = isOCRProcessed
        self.createdAt = createdAt
        self.document = document
    }
}
