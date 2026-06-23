//
//  PreviewData.swift
//  IronLog
//
//  仅供 SwiftUI #Preview 使用的内存数据库与示例数据。
//

import Foundation
import SwiftData

@MainActor
enum PreviewData {

    /// 内存容器，含示例动作、训练与 PR。
    static let container: ModelContainer = {
        let schema = Schema([
            Exercise.self,
            WorkoutSession.self,
            SetEntry.self,
            PersonalRecord.self,
            WorkoutTemplate.self,
            TemplateExercise.self,
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: config)
        let context = container.mainContext

        SeedData.seedIfNeeded(context)
        seedSampleHistory(context)
        return container
    }()

    /// 取一个示例动作（深蹲），用于单视图预览。
    static var sampleExercise: Exercise {
        let descriptor = FetchDescriptor<Exercise>(predicate: #Predicate { $0.id == "ex.squat" })
        return (try? container.mainContext.fetch(descriptor))?.first
            ?? Exercise(name: "深蹲", muscleGroup: .quads, equipment: .barbell)
    }

    /// 取一个示例进行中训练。
    static var sampleSession: WorkoutSession {
        let descriptor = FetchDescriptor<WorkoutSession>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        return (try? container.mainContext.fetch(descriptor))?.first
            ?? WorkoutSession(name: "推日")
    }

    /// 写入几条历史训练，便于图表/历史页预览。
    private static func seedSampleHistory(_ context: ModelContext) {
        func exercise(_ id: String) -> Exercise? {
            try? context.fetch(
                FetchDescriptor<Exercise>(predicate: #Predicate { $0.id == id })
            ).first
        }
        guard let bench = exercise("ex.bench_press"),
              let squat = exercise("ex.squat") else { return }

        let now = Date(timeIntervalSince1970: 1_718_000_000) // 固定时间，预览稳定
        for week in 0..<6 {
            let date = now.addingTimeInterval(TimeInterval(-week * 7 * 86400))
            let session = WorkoutSession(name: "推日", date: date, endDate: date.addingTimeInterval(3600))
            context.insert(session)
            var order = 0
            for set in 0..<3 {
                let entry = SetEntry(
                    order: order,
                    weight: 80 + Double(set * 5) - Double(week * 2),
                    reps: 5,
                    rpe: 8,
                    isCompleted: true,
                    timestamp: date,
                    session: session,
                    exercise: bench
                )
                context.insert(entry)
                order += 1
            }
            for set in 0..<3 {
                let entry = SetEntry(
                    order: order,
                    weight: 100 + Double(set * 5) - Double(week * 2),
                    reps: 5,
                    rpe: 8,
                    isCompleted: true,
                    timestamp: date,
                    session: session,
                    exercise: squat
                )
                context.insert(entry)
                order += 1
            }
        }
        try? context.save()
    }
}
