//
//  AchievementRecord.swift
//  LumenPuzzle
//
//  SwiftData 持久化模型：记录已解锁的成就。
//

import Foundation
import SwiftData

/// 已解锁成就记录。一条记录代表一个成就被点亮。
@Model
final class AchievementRecord {

    /// 成就标识（对应 `Achievement.id` 的 rawValue）。
    @Attribute(.unique) var identifier: String

    /// 解锁时间。
    var unlockedAt: Date

    init(identifier: String, unlockedAt: Date = .now) {
        self.identifier = identifier
        self.unlockedAt = unlockedAt
    }
}
