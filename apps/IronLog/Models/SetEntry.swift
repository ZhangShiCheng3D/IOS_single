//
//  SetEntry.swift
//  IronLog
//
//  单组记录：一个动作的一组（重量 × 次数 + RPE）。
//  这是录入速度优化的核心实体——力求最少字段、最快输入。
//

import Foundation
import SwiftData

/// 单组训练记录。
@Model
final class SetEntry {
    @Attribute(.unique) var id: UUID
    /// 在所属训练中的排序（用于稳定顺序）。
    var order: Int
    /// 重量（公斤；显示时按单位偏好换算）。
    var weight: Double
    /// 次数。
    var reps: Int
    /// RPE（自觉用力程度，6.0–10.0，0 表示未填）。
    var rpe: Double
    /// 是否为热身组（热身组不计入容量与 PR）。
    var isWarmup: Bool
    /// 是否已完成（勾选打钩）。
    var isCompleted: Bool
    /// 记录时间。
    var timestamp: Date

    /// 所属训练。
    var session: WorkoutSession?
    /// 对应动作。
    var exercise: Exercise?

    init(
        id: UUID = UUID(),
        order: Int = 0,
        weight: Double = 0,
        reps: Int = 0,
        rpe: Double = 0,
        isWarmup: Bool = false,
        isCompleted: Bool = false,
        timestamp: Date = .now,
        session: WorkoutSession? = nil,
        exercise: Exercise? = nil
    ) {
        self.id = id
        self.order = order
        self.weight = weight
        self.reps = reps
        self.rpe = rpe
        self.isWarmup = isWarmup
        self.isCompleted = isCompleted
        self.timestamp = timestamp
        self.session = session
        self.exercise = exercise
    }

    // MARK: - 计算属性

    /// 单组容量 = 重量 × 次数。
    var volume: Double { weight * Double(reps) }

    /// 估算 1RM（Epley 公式）：weight × (1 + reps/30)。
    /// 仅在重量与次数有效时给出。
    var estimatedOneRepMax: Double {
        guard weight > 0, reps > 0 else { return 0 }
        if reps == 1 { return weight }
        return weight * (1.0 + Double(reps) / 30.0)
    }
}
