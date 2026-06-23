//
//  HabitEntry.swift
//  HabitGrid
//
//  每日打卡记录（SwiftData @Model）。
//

import Foundation
import SwiftData

/// 一条打卡记录。每个习惯每天至多一条记录。
@Model
final class HabitEntry {
    /// 打卡所属日期，统一归一化到当天 00:00（本地时区），作为唯一日键。
    var day: Date

    /// 打卡强度（1...4）。用于热力图浓淡，默认 1。
    /// 支持“多次打卡 = 更深颜色”的 GitHub 风格表达。
    var intensity: Int

    /// 创建时间戳（用于排序/审计）。
    var createdAt: Date

    /// 反向关联到习惯。
    var habit: Habit?

    init(day: Date, intensity: Int = 1, createdAt: Date = .now, habit: Habit? = nil) {
        self.day = Calendar.current.startOfDay(for: day)
        self.intensity = max(1, min(4, intensity))
        self.createdAt = createdAt
        self.habit = habit
    }
}
