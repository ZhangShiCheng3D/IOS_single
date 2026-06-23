//
//  ScanDocument.swift
//  DocScanPro
//
//  扫描文档模型。一个文档由一页或多页扫描页面组成，
//  可归属于一个文件夹、绑定多个标签，并聚合所有页面的 OCR 文本。
//

import Foundation
import SwiftData

@Model
final class ScanDocument {

    /// 稳定唯一标识，用于排序、分享、去重。
    @Attribute(.unique) var id: UUID

    /// 文档标题，默认以创建时间命名，用户可重命名。
    var title: String

    var createdAt: Date
    var updatedAt: Date

    /// 是否被用户标记为收藏。
    var isFavorite: Bool

    /// 页面集合。删除文档时级联删除所有页面，避免孤儿数据。
    @Relationship(deleteRule: .cascade, inverse: \ScannedPage.document)
    var pages: [ScannedPage]

    /// 所属文件夹（可为空，表示“未分类”）。
    @Relationship(inverse: \Folder.documents)
    var folder: Folder?

    /// 标签集合，多对多。
    @Relationship(inverse: \Tag.documents)
    var tags: [Tag]

    init(
        id: UUID = UUID(),
        title: String,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        isFavorite: Bool = false,
        pages: [ScannedPage] = [],
        folder: Folder? = nil,
        tags: [Tag] = []
    ) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isFavorite = isFavorite
        self.pages = pages
        self.folder = folder
        self.tags = tags
    }
}

// MARK: - 派生属性

extension ScanDocument {

    /// 按页码顺序排列的页面。
    var orderedPages: [ScannedPage] {
        pages.sorted { $0.order < $1.order }
    }

    /// 页数。
    var pageCount: Int { pages.count }

    /// 聚合全文：所有页面 OCR 文本按页序拼接，供搜索与复制使用。
    var combinedText: String {
        orderedPages
            .map { $0.recognizedText }
            .filter { !$0.isEmpty }
            .joined(separator: "\n\n")
    }

    /// 是否存在任意已识别文本。
    var hasRecognizedText: Bool {
        pages.contains { !$0.recognizedText.isEmpty }
    }

    /// 用于列表展示的首页缩略图数据。
    var thumbnailData: Data? {
        orderedPages.first?.imageData
    }

    /// 判断文档是否匹配搜索关键字（标题 + 全文 + 标签）。
    func matches(query: String) -> Bool {
        guard !query.isEmpty else { return true }
        let needle = query.lowercased()
        // 先比对廉价字段（标题、标签），最后才计算并比对开销较大的全文 combinedText。
        if title.lowercased().contains(needle) { return true }
        if tags.contains(where: { $0.name.lowercased().contains(needle) }) { return true }
        if combinedText.lowercased().contains(needle) { return true }
        return false
    }
}
