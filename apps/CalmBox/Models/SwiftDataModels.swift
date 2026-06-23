//
//  SwiftDataModels.swift
//  CalmBox
//
//  SwiftData 持久化模型：收藏场景、冥想记录、混音预设。
//

import Foundation
import SwiftData

/// 用户收藏的场景。
@Model
final class FavoriteRecord {
    /// 对应 RelaxScene.id。
    @Attribute(.unique) var sceneID: String
    var createdAt: Date

    init(sceneID: String, createdAt: Date = .now) {
        self.sceneID = sceneID
        self.createdAt = createdAt
    }
}

/// 一次冥想/计时会话的记录，用于统计与回顾。
@Model
final class MeditationSession {
    var id: UUID
    /// 计划时长（秒）。
    var plannedDuration: TimeInterval
    /// 实际完成时长（秒）。
    var completedDuration: TimeInterval
    /// 是否完整完成（未中途退出）。
    var isCompleted: Bool
    var startedAt: Date

    init(
        id: UUID = UUID(),
        plannedDuration: TimeInterval,
        completedDuration: TimeInterval,
        isCompleted: Bool,
        startedAt: Date = .now
    ) {
        self.id = id
        self.plannedDuration = plannedDuration
        self.completedDuration = completedDuration
        self.isCompleted = isCompleted
        self.startedAt = startedAt
    }
}

/// 用户保存的白噪音混音预设。
@Model
final class MixerPreset {
    var id: UUID
    var name: String
    /// 混音配置：声源 id -> 音量(0...1)，以 JSON 字符串持久化。
    var mixData: Data
    var createdAt: Date

    init(id: UUID = UUID(), name: String, mix: [String: Float], createdAt: Date = .now) {
        self.id = id
        self.name = name
        self.mixData = (try? JSONEncoder().encode(mix)) ?? Data()
        self.createdAt = createdAt
    }

    /// 解码混音配置。
    var mix: [String: Float] {
        get { (try? JSONDecoder().decode([String: Float].self, from: mixData)) ?? [:] }
        set { mixData = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }
}
