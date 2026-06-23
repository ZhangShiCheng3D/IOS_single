//
//  HabitStatistics.swift
//  HabitGrid
//
//  纯函数式统计计算：连续天数、完成率、最长连续。与 SwiftData 解耦，便于测试。
//

import Foundation

/// 单个习惯的统计结果快照。
struct HabitStats: Equatable {
    var currentStreak: Int = 0      // 当前连续天数
    var longestStreak: Int = 0      // 历史最长连续天数
    var totalCompletions: Int = 0   // 累计打卡天数
    var completionRate: Double = 0  // 完成率（基于计划日）0...1
    var thisWeekCount: Int = 0      // 本周打卡次数
}

enum HabitStatistics {

    /// 从一组打卡日期集合计算统计。
    /// - Parameters:
    ///   - completedDays: 已打卡的“当天 00:00”日期集合。
    ///   - frequency: 习惯频率，用于完成率分母与连续性判定。
    ///   - createdAt: 习惯创建日期，作为完成率统计起点。
    ///   - referenceDate: 计算“今天”的基准（默认现在）。
    static func compute(
        completedDays: Set<Date>,
        frequency: HabitFrequency,
        weeklyTarget: Int,
        createdAt: Date,
        referenceDate: Date = .now,
        calendar: Calendar = .current
    ) -> HabitStats {
        var stats = HabitStats()
        stats.totalCompletions = completedDays.count

        guard !completedDays.isEmpty else {
            // 仍计算本周计数（为 0）与完成率（0）。
            return stats
        }

        let today = calendar.startOfDay(for: referenceDate)

        // MARK: 当前连续天数
        // 从今天（或最近的计划日）向前回溯，遇到未完成的计划日即中断。
        // 若今天是计划日但尚未打卡，则从昨天开始计（不惩罚“今天还没到”）。
        stats.currentStreak = currentStreak(
            completedDays: completedDays,
            frequency: frequency,
            today: today,
            calendar: calendar
        )

        // MARK: 最长连续天数
        stats.longestStreak = longestStreak(
            completedDays: completedDays,
            frequency: frequency,
            calendar: calendar
        )

        // MARK: 完成率（计划日中已完成的比例）
        stats.completionRate = completionRate(
            completedDays: completedDays,
            frequency: frequency,
            weeklyTarget: weeklyTarget,
            from: calendar.startOfDay(for: createdAt),
            to: today,
            calendar: calendar
        )

        // MARK: 本周计数
        stats.thisWeekCount = thisWeekCount(
            completedDays: completedDays,
            today: today,
            calendar: calendar
        )

        return stats
    }

    // MARK: - 私有计算

    private static func currentStreak(
        completedDays: Set<Date>,
        frequency: HabitFrequency,
        today: Date,
        calendar: Calendar
    ) -> Int {
        var streak = 0
        var cursor = today

        // 如果今天是计划日但未打卡，从昨天开始评估（今天尚有机会完成）。
        if frequency.isScheduled(on: cursor, calendar: calendar),
           !completedDays.contains(cursor) {
            cursor = cursor.adding(days: -1, calendar: calendar)
        }

        // 向前回溯。
        var safety = 0
        while safety < 4000 { // 安全上限，避免极端坏数据死循环
            safety += 1
            if frequency.isScheduled(on: cursor, calendar: calendar) {
                if completedDays.contains(cursor) {
                    streak += 1
                } else {
                    break
                }
            }
            cursor = cursor.adding(days: -1, calendar: calendar)
            // 越过最早记录则停止。
            if let earliest = completedDays.min(), cursor < earliest {
                break
            }
        }
        return streak
    }

    private static func longestStreak(
        completedDays: Set<Date>,
        frequency: HabitFrequency,
        calendar: Calendar
    ) -> Int {
        guard let earliest = completedDays.min(),
              let latest = completedDays.max() else { return 0 }

        var longest = 0
        var running = 0
        var cursor = earliest

        var safety = 0
        while cursor <= latest && safety < 8000 {
            safety += 1
            if frequency.isScheduled(on: cursor, calendar: calendar) {
                if completedDays.contains(cursor) {
                    running += 1
                    longest = max(longest, running)
                } else {
                    running = 0
                }
            }
            cursor = cursor.adding(days: 1, calendar: calendar)
        }
        return longest
    }

    private static func completionRate(
        completedDays: Set<Date>,
        frequency: HabitFrequency,
        weeklyTarget: Int,
        from start: Date,
        to end: Date,
        calendar: Calendar
    ) -> Double {
        guard start <= end else { return 0 }

        switch frequency {
        case .custom:
            // 自定义：以“周数 × 每周目标”为分母。
            let days = (calendar.dateComponents([.day], from: start, to: end).day ?? 0) + 1
            let weeks = max(1.0, Double(days) / 7.0)
            let denominator = weeks * Double(max(1, weeklyTarget))
            return min(1.0, Double(completedDays.count) / denominator)

        default:
            // 统计区间内的计划日总数。
            var scheduled = 0
            var cursor = start
            var safety = 0
            while cursor <= end && safety < 8000 {
                safety += 1
                if frequency.isScheduled(on: cursor, calendar: calendar) {
                    scheduled += 1
                }
                cursor = cursor.adding(days: 1, calendar: calendar)
            }
            guard scheduled > 0 else { return 0 }
            let completedScheduled = completedDays.filter {
                $0 >= start && $0 <= end && frequency.isScheduled(on: $0, calendar: calendar)
            }.count
            return min(1.0, Double(completedScheduled) / Double(scheduled))
        }
    }

    private static func thisWeekCount(
        completedDays: Set<Date>,
        today: Date,
        calendar: Calendar
    ) -> Int {
        let weekday = calendar.component(.weekday, from: today)
        guard let sunday = calendar.date(byAdding: .day, value: -(weekday - 1), to: today) else { return 0 }
        return completedDays.filter { $0 >= sunday && $0 <= today }.count
    }
}
