//
//  HabitViewModel.swift
//  HabitGrid
//
//  习惯业务逻辑：打卡切换、增删改、统计计算。封装对 ModelContext 的操作。
//

import Foundation
import SwiftData
import SwiftUI

/// 面向视图的习惯操作 ViewModel。
@Observable
@MainActor
final class HabitViewModel {

    /// SwiftData 上下文。由视图注入。
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    // MARK: - 打卡

    /// 切换某习惯在指定日期的打卡状态。
    /// 已打卡 → 取消；未打卡 → 新增（intensity = 1）。
    /// - Returns: 切换后是否为“已打卡”。
    @discardableResult
    func toggleCheckIn(for habit: Habit, on date: Date = .now) -> Bool {
        let day = date.startOfDay

        if let existing = habit.entries.first(where: { $0.day == day }) {
            context.delete(existing)
            habit.entries.removeAll { $0.day == day }
            saveAndSync(habit)
            Haptics.selection()
            return false
        } else {
            let entry = HabitEntry(day: day, intensity: 1, habit: habit)
            context.insert(entry)
            habit.entries.append(entry)
            saveAndSync(habit)
            Haptics.tap()

            // 若达成新的最长连续纪录，给予成功反馈。
            let stats = stats(for: habit)
            if stats.currentStreak > 0 && stats.currentStreak == stats.longestStreak {
                Haptics.success()
            }
            return true
        }
    }

    /// 增加某习惯当天的打卡强度（用于“多次完成”）。封顶 4。
    func bumpIntensity(for habit: Habit, on date: Date = .now) {
        let day = date.startOfDay
        if let existing = habit.entries.first(where: { $0.day == day }) {
            existing.intensity = min(4, existing.intensity + 1)
        } else {
            let entry = HabitEntry(day: day, intensity: 1, habit: habit)
            context.insert(entry)
            habit.entries.append(entry)
        }
        saveAndSync(habit)
        Haptics.tap()
    }

    /// 判断习惯今天是否已打卡。
    func isCompletedToday(_ habit: Habit) -> Bool {
        let today = Date.now.startOfDay
        return habit.entries.contains { $0.day == today }
    }

    /// 返回某习惯指定日期的强度（0 = 未打卡）。
    func intensity(for habit: Habit, on date: Date) -> Int {
        let day = date.startOfDay
        return habit.entries.first(where: { $0.day == day })?.intensity ?? 0
    }

    // MARK: - 统计

    /// 计算习惯统计快照。
    func stats(for habit: Habit) -> HabitStats {
        let days = Set(habit.entries.map { $0.day })
        return HabitStatistics.compute(
            completedDays: days,
            frequency: habit.frequency,
            weeklyTarget: habit.weeklyTarget,
            createdAt: habit.createdAt
        )
    }

    // MARK: - CRUD

    /// 创建习惯。调用方需先校验免费额度。
    func createHabit(
        name: String,
        iconName: String,
        colorHex: String,
        frequency: HabitFrequency,
        weeklyTarget: Int,
        reminderEnabled: Bool,
        reminderTime: Date?,
        currentCount: Int
    ) -> Habit {
        let habit = Habit(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            iconName: iconName,
            colorHex: colorHex,
            frequency: frequency,
            weeklyTarget: weeklyTarget,
            sortOrder: currentCount,
            reminderEnabled: reminderEnabled,
            reminderTime: reminderTime
        )
        context.insert(habit)
        save()
        scheduleReminderIfNeeded(for: habit)
        return habit
    }

    /// 应用对已存在习惯的编辑。
    func update(_ habit: Habit) {
        save()
        scheduleReminderIfNeeded(for: habit)
    }

    /// 删除习惯。
    func delete(_ habit: Habit) {
        NotificationManager.shared.cancelReminder(habitID: habit.id)
        context.delete(habit)
        save()
    }

    /// 重新排序：把习惯数组的当前顺序写回 sortOrder。
    func persistOrder(_ habits: [Habit]) {
        for (index, habit) in habits.enumerated() {
            habit.sortOrder = index
        }
        save()
    }

    // MARK: - 提醒

    private func scheduleReminderIfNeeded(for habit: Habit) {
        Task {
            if habit.reminderEnabled, let time = habit.reminderTime {
                await NotificationManager.shared.scheduleReminder(
                    habitID: habit.id,
                    title: habit.name,
                    time: time
                )
            } else {
                NotificationManager.shared.cancelReminder(habitID: habit.id)
            }
        }
    }

    // MARK: - 持久化

    private func save() {
        do {
            try context.save()
        } catch {
            print("SwiftData 保存失败: \(error.localizedDescription)")
        }
    }

    /// 保存并同步 Widget 数据。
    private func saveAndSync(_ habit: Habit) {
        save()
        WidgetDataBridge.sync(from: context)
    }
}
