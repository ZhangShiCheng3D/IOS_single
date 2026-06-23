//
//  Folder.swift
//  DocScanPro
//
//  文件夹模型，用于对文档进行分组管理。
//

import Foundation
import SwiftData

@Model
final class Folder {

    @Attribute(.unique) var id: UUID

    var name: String

    /// SF Symbol 名称，用于在列表中展示文件夹图标。
    var symbolName: String

    var createdAt: Date

    /// 文件夹下的文档。删除文件夹时不删除文档，只解除归属。
    @Relationship(deleteRule: .nullify)
    var documents: [ScanDocument]

    init(
        id: UUID = UUID(),
        name: String,
        symbolName: String = "folder.fill",
        createdAt: Date = .now,
        documents: [ScanDocument] = []
    ) {
        self.id = id
        self.name = name
        self.symbolName = symbolName
        self.createdAt = createdAt
        self.documents = documents
    }

    /// 文件夹内文档数量。
    var documentCount: Int { documents.count }
}
