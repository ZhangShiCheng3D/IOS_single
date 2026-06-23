//
//  WaterEntry.swift
//  FastFlow
//
//  单次喝水记录。每喝一次写入一条，按天聚合计算饮水进度。
//

import Foundation
import SwiftData

@Model
final class WaterEntry {
    /// 记录唯一标识。
    @Attribute(.unique) var id: UUID
    /// 饮水量（毫升）。
    var amountML: Int
    /// 记录时间戳。
    var timestamp: Date

    init(id: UUID = UUID(), amountML: Int, timestamp: Date = .now) {
        self.id = id
        self.amountML = amountML
        self.timestamp = timestamp
    }
}

// MARK: - 常用饮水量快捷选项

extension WaterEntry {
    /// 快捷添加的杯量选项（毫升）。
    static let quickAmounts: [Int] = [100, 200, 300, 500]
}
