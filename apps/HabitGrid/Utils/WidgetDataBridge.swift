//
//  WidgetDataBridge.swift
//  HabitGrid
//
//  主 App 与 Widget 之间通过 App Group 共享“今日习惯”数据。
//  Widget 不直接访问 SwiftData，避免容器迁移/并发复杂度，改用轻量快照。
//

import Foundation
import SwiftData
#if canImport(WidgetKit)
import WidgetKit
#endif

/// Widget 渲染所需的单个习惯轻量快照（可 Codable）。
struct HabitSnapshot: Codable, Identifiable, Hashable {
    let id: UUID
    let name: String
    let iconName: String
    let colorHex: String
    let isCompletedToday: Bool
    let currentStreak: Int
}

/// App Group 共享存储桥。
enum WidgetDataBridge {

    /// App Group 标识。需在主 App 与 Widget Target 的 Capabilities 中配置一致。
    static let appGroupID = "group.com.habitgrid.shared"

    private static let snapshotKey = "habitgrid.widget.snapshots"
    private static let widgetKind = "HabitGridWidget"

    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }

    /// 从 SwiftData 上下文读取全部习惯，生成快照并写入共享存储，随后刷新 Widget。
    @MainActor
    static func sync(from context: ModelContext) {
        let descriptor = FetchDescriptor<Habit>(
            sortBy: [SortDescriptor(\.sortOrder, order: .forward)]
        )
        guard let habits = try? context.fetch(descriptor) else { return }

        let snapshots = habits.prefix(6).map { habit -> HabitSnapshot in
            let days = Set(habit.entries.map { $0.day })
            let stats = HabitStatistics.compute(
                completedDays: days,
                frequency: habit.frequency,
                weeklyTarget: habit.weeklyTarget,
                createdAt: habit.createdAt
            )
            return HabitSnapshot(
                id: habit.id,
                name: habit.name,
                iconName: habit.iconName,
                colorHex: habit.colorHex,
                isCompletedToday: days.contains(Date.now.startOfDay),
                currentStreak: stats.currentStreak
            )
        }
        save(Array(snapshots))
    }

    /// 写入快照数组。
    static func save(_ snapshots: [HabitSnapshot]) {
        guard let defaults else { return }
        if let data = try? JSONEncoder().encode(snapshots) {
            defaults.set(data, forKey: snapshotKey)
        }
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadTimelines(ofKind: widgetKind)
        #endif
    }

    /// 读取快照数组（供 Widget 使用）。
    static func load() -> [HabitSnapshot] {
        guard let defaults,
              let data = defaults.data(forKey: snapshotKey),
              let snapshots = try? JSONDecoder().decode([HabitSnapshot].self, from: data) else {
            return []
        }
        return snapshots
    }
}
