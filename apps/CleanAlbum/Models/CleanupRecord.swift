//
//  CleanupRecord.swift
//  CleanAlbum
//
//  一次清理操作的历史记录，用于"清理后空间对比"。
//

import Foundation
import SwiftData

/// 单次清理记录。
@Model
final class CleanupRecord {

    /// 清理时间。
    var date: Date

    /// 删除的照片数量。
    var deletedCount: Int

    /// 释放的字节数（估算）。
    var freedBytes: Int64

    /// 清理类型描述（重复 / 相似 / 模糊 / 混合）。
    var category: String

    init(date: Date = .now, deletedCount: Int, freedBytes: Int64, category: String) {
        self.date = date
        self.deletedCount = deletedCount
        self.freedBytes = freedBytes
        self.category = category
    }
}
