//
//  Tag.swift
//  DocScanPro
//
//  标签模型，多对多关联文档，支持彩色标记与按标签筛选。
//

import Foundation
import SwiftData
import SwiftUI

@Model
final class Tag {

    @Attribute(.unique) var id: UUID

    var name: String

    /// 标签颜色，以十六进制字符串存储（如 "#FF6B6B"）。
    var colorHex: String

    var createdAt: Date

    @Relationship(deleteRule: .nullify)
    var documents: [ScanDocument]

    init(
        id: UUID = UUID(),
        name: String,
        colorHex: String = "#4A90D9",
        createdAt: Date = .now,
        documents: [ScanDocument] = []
    ) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.createdAt = createdAt
        self.documents = documents
    }

    /// 将存储的十六进制字符串转换为 SwiftUI Color。
    var color: Color {
        Color(hex: colorHex) ?? .accentColor
    }
}

extension Tag {
    /// 预设可选标签颜色，供创建标签时选择。
    static let presetColors: [String] = [
        "#FF6B6B", "#F7B731", "#26DE81", "#4A90D9",
        "#A55EEA", "#FD9644", "#2BCBBA", "#778CA3"
    ]
}
