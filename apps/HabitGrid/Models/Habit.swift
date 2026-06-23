//
//  Habit.swift
//  HabitGrid
//
//  习惯数据模型（SwiftData @Model）。
//

import Foundation
import SwiftData
import SwiftUI

/// 目标频率：决定“今天是否需要打卡”的判定规则。
enum HabitFrequency: Int, Codable, CaseIterable, Identifiable {
    case daily          // 每天
    case weekdays       // 工作日（周一至周五）
    case weekends       // 周末
    case custom         // 自定义：每周 N 天（仅用于目标统计）

    var id: Int { rawValue }

    var displayName: LocalizedStringKey {
        switch self {
        case .daily:    return "frequency.daily"
        case .weekdays: return "frequency.weekdays"
        case .weekends: return "frequency.weekends"
        case .custom:   return "frequency.custom"
        }
    }

    /// 判断给定日期是否属于该习惯的“计划日”。
    func isScheduled(on date: Date, calendar: Calendar = .current) -> Bool {
        let weekday = calendar.component(.weekday, from: date) // 1 = 周日 ... 7 = 周六
        switch self {
        case .daily:
            return true
        case .weekdays:
            return (2...6).contains(weekday)
        case .weekends:
            return weekday == 1 || weekday == 7
        case .custom:
            return true // 自定义频率不限制具体星期，按目标次数统计
        }
    }
}

/// 单个习惯。
@Model
final class Habit {
    /// 稳定唯一标识，用于 Widget 深链与导出。
    @Attribute(.unique) var id: UUID

    /// 习惯名称。
    var name: String

    /// SF Symbol 图标名称。
    var iconName: String

    /// 颜色主题键（对应 ColorPalette.heatmapColor）。存储为 hex 以便 Widget 直接渲染。
    var colorHex: String

    /// 目标频率原始值。
    var frequencyRaw: Int

    /// 自定义频率：每周目标次数（仅 frequency == .custom 时有意义）。
    var weeklyTarget: Int

    /// 创建时间。
    var createdAt: Date

    /// 排序权重（越小越靠前）。
    var sortOrder: Int

    /// 是否启用提醒。
    var reminderEnabled: Bool

    /// 提醒时间（仅取时分），nil 表示未设置。
    var reminderTime: Date?

    /// 关联的每日打卡记录。删除习惯时级联删除所有记录。
    @Relationship(deleteRule: .cascade, inverse: \HabitEntry.habit)
    var entries: [HabitEntry] = []

    init(
        id: UUID = UUID(),
        name: String,
        iconName: String = "checkmark.seal.fill",
        colorHex: String = "#39D353",
        frequency: HabitFrequency = .daily,
        weeklyTarget: Int = 7,
        createdAt: Date = .now,
        sortOrder: Int = 0,
        reminderEnabled: Bool = false,
        reminderTime: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.iconName = iconName
        self.colorHex = colorHex
        self.frequencyRaw = frequency.rawValue
        self.weeklyTarget = weeklyTarget
        self.createdAt = createdAt
        self.sortOrder = sortOrder
        self.reminderEnabled = reminderEnabled
        self.reminderTime = reminderTime
    }

    /// 类型安全的频率访问器。
    var frequency: HabitFrequency {
        get { HabitFrequency(rawValue: frequencyRaw) ?? .daily }
        set { frequencyRaw = newValue.rawValue }
    }

    /// 习惯主色。
    var color: Color {
        Color(hex: colorHex) ?? .green
    }
}
