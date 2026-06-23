//
//  WorkoutTemplate.swift
//  IronLog
//
//  训练计划模板：内置 5/3/1、PPL、Push/Pull 等，也支持自定义。
//

import Foundation
import SwiftData

/// 模板中的单个动作计划项（目标组数 × 次数）。
@Model
final class TemplateExercise {
    @Attribute(.unique) var id: UUID
    /// 动作稳定 ID（指向内置或自定义动作）。
    var exerciseID: String
    /// 动作名称快照。
    var exerciseName: String
    /// 排序。
    var order: Int
    /// 目标组数。
    var targetSets: Int
    /// 目标次数（如 5）。
    var targetReps: Int
    /// 备注（如「@75% 1RM」「AMRAP」）。
    var prescription: String

    var template: WorkoutTemplate?

    init(
        id: UUID = UUID(),
        exerciseID: String,
        exerciseName: String,
        order: Int,
        targetSets: Int,
        targetReps: Int,
        prescription: String = ""
    ) {
        self.id = id
        self.exerciseID = exerciseID
        self.exerciseName = exerciseName
        self.order = order
        self.targetSets = targetSets
        self.targetReps = targetReps
        self.prescription = prescription
    }
}

/// 训练计划模板。
@Model
final class WorkoutTemplate {
    @Attribute(.unique) var id: UUID
    var name: String
    /// 简短描述（流派/适用人群）。
    var detail: String
    /// 是否为内置模板（不可删除，但可复制）。
    var isBuiltIn: Bool
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \TemplateExercise.template)
    var exercises: [TemplateExercise] = []

    init(
        id: UUID = UUID(),
        name: String,
        detail: String = "",
        isBuiltIn: Bool = false,
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.detail = detail
        self.isBuiltIn = isBuiltIn
        self.createdAt = createdAt
    }

    /// 按顺序排列的动作项。
    var orderedExercises: [TemplateExercise] {
        exercises.sorted { $0.order < $1.order }
    }
}
