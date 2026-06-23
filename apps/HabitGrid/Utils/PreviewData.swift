//
//  PreviewData.swift
//  HabitGrid
//
//  SwiftUI 预览用的内存数据容器与示例习惯。
//

import Foundation
import SwiftData

enum PreviewData {

    /// 含示例数据的内存容器，仅供 #Preview 使用。
    @MainActor
    static let container: ModelContainer = {
        let schema = Schema([Habit.self, HabitEntry.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        do {
            let container = try ModelContainer(for: schema, configurations: [config])
            seed(into: container.mainContext)
            return container
        } catch {
            fatalError("预览容器创建失败: \(error)")
        }
    }()

    /// 取容器中的第一个示例习惯（供详情页预览）。
    @MainActor
    static var sampleHabit: Habit {
        let descriptor = FetchDescriptor<Habit>(sortBy: [SortDescriptor(\.sortOrder)])
        if let first = try? container.mainContext.fetch(descriptor).first {
            return first
        }
        // 兜底：返回一个未插入的临时习惯。
        return Habit(name: "示例习惯", iconName: "star.fill", colorHex: "#39D353")
    }

    /// 写入若干示例习惯及打卡历史。
    @MainActor
    static func seed(into context: ModelContext) {
        let samples: [(String, String, String, HabitFrequency)] = [
            ("每天阅读", "book.fill", "#8B5CF6", .daily),
            ("晨跑", "figure.run", "#F97316", .daily),
            ("喝水 2L", "drop.fill", "#06B6D4", .daily)
        ]

        let calendar = Calendar.current
        for (index, sample) in samples.enumerated() {
            let habit = Habit(
                name: sample.0,
                iconName: sample.1,
                colorHex: sample.2,
                frequency: sample.3,
                sortOrder: index,
                reminderEnabled: false
            )
            context.insert(habit)

            // 生成近 80 天的确定性打卡记录（伪随机但稳定）。
            for offset in 0..<80 {
                let seed = (offset * 7 + index * 13) % 10
                guard seed < 6 else { continue } // 约 60% 完成率
                let date = calendar.date(byAdding: .day, value: -offset, to: .now)!
                let entry = HabitEntry(
                    day: date,
                    intensity: (seed % 4) + 1,
                    habit: habit
                )
                context.insert(entry)
                habit.entries.append(entry)
            }
        }
        try? context.save()
    }
}
