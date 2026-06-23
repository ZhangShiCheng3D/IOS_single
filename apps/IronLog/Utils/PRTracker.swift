//
//  PRTracker.swift
//  IronLog
//
//  个人纪录追踪：当一组被完成时，检查是否刷新了任一类型的 PR，
//  若是则更新 PersonalRecord 并触发祝贺通知。
//

import Foundation
import SwiftData

@MainActor
enum PRTracker {

    /// 处理一组完成事件，返回本组刷新的 PR 类型列表（用于 UI 高亮）。
    @discardableResult
    static func evaluate(set: SetEntry, in context: ModelContext) -> [PRType] {
        guard let exercise = set.exercise,
              set.isCompleted, !set.isWarmup,
              set.weight > 0, set.reps > 0 else { return [] }

        var brokenTypes: [PRType] = []

        let candidates: [(PRType, Double)] = [
            (.maxWeight, set.weight),
            (.estimatedOneRM, set.estimatedOneRepMax),
            (.maxVolume, set.volume),
            (.maxReps, Double(set.reps)),
        ]

        for (type, value) in candidates {
            if updateRecord(
                exercise: exercise,
                type: type,
                value: value,
                weight: set.weight,
                reps: set.reps,
                date: set.timestamp,
                context: context
            ) {
                brokenTypes.append(type)
            }
        }

        if !brokenTypes.isEmpty {
            try? context.save()
            // 仅就最具代表性的 1RM / 重量 PR 发通知，避免刷屏。
            if brokenTypes.contains(.estimatedOneRM) || brokenTypes.contains(.maxWeight) {
                // 通知文案遵循用户的单位偏好（DB 存 kg，显示按偏好换算）。
                let detail = "\(Fmt.weight(set.weight, unit: WeightUnit.preferred)) × \(set.reps)"
                NotificationManager.shared.notifyPR(exerciseName: exercise.name, detail: detail)
            }
        }

        return brokenTypes
    }

    /// 更新单一类型记录，返回是否刷新。
    private static func updateRecord(
        exercise: Exercise,
        type: PRType,
        value: Double,
        weight: Double,
        reps: Int,
        date: Date,
        context: ModelContext
    ) -> Bool {
        guard value > 0 else { return false }

        let exID = exercise.id
        let typeRaw = type.rawValue
        let descriptor = FetchDescriptor<PersonalRecord>(
            predicate: #Predicate { $0.exerciseID == exID && $0.typeRaw == typeRaw }
        )
        let existing = (try? context.fetch(descriptor))?.first

        if let record = existing {
            // 用 0.01 容差避免浮点抖动误判刷新。
            guard value > record.value + 0.01 else { return false }
            record.value = value
            record.weight = weight
            record.reps = reps
            record.date = date
            record.exerciseName = exercise.name
            return true
        } else {
            let record = PersonalRecord(
                exerciseID: exID,
                exerciseName: exercise.name,
                type: type,
                value: value,
                weight: weight,
                reps: reps,
                date: date
            )
            context.insert(record)
            return true
        }
    }

    /// 取某动作的所有当前 PR。
    static func records(for exerciseID: String, in context: ModelContext) -> [PersonalRecord] {
        let descriptor = FetchDescriptor<PersonalRecord>(
            predicate: #Predicate { $0.exerciseID == exerciseID },
            sortBy: [SortDescriptor(\.typeRaw)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }
}
