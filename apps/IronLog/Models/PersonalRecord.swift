//
//  PersonalRecord.swift
//  IronLog
//
//  个人纪录（PR）：按动作追踪历史最佳，自动更新并触发通知。
//

import Foundation
import SwiftData

/// PR 类型。
enum PRType: String, Codable, CaseIterable, Identifiable {
    case maxWeight       // 单次最大重量
    case estimatedOneRM  // 估算 1RM
    case maxVolume       // 单组最大容量
    case maxReps         // 给定重量下最大次数（简化为最大次数）

    var id: String { rawValue }
    var localizedNameKey: String { "pr.type.\(rawValue)" }

    var systemImage: String {
        switch self {
        case .maxWeight:      return "scalemass.fill"
        case .estimatedOneRM: return "crown.fill"
        case .maxVolume:      return "chart.bar.fill"
        case .maxReps:        return "repeat"
        }
    }
}

/// 一条个人纪录。每个 (动作, 类型) 维护一条「当前最佳」记录。
@Model
final class PersonalRecord {
    @Attribute(.unique) var id: UUID
    /// 对应动作的稳定 ID。
    var exerciseID: String
    /// 动作名称快照（便于在动作被删时仍可展示）。
    var exerciseName: String
    /// PR 类型。
    var typeRaw: String
    /// 数值（重量 kg / 1RM kg / 容量 kg / 次数）。
    var value: Double
    /// 达成时的重量与次数（用于展示「100kg × 5」）。
    var weight: Double
    var reps: Int
    /// 达成日期。
    var date: Date

    init(
        id: UUID = UUID(),
        exerciseID: String,
        exerciseName: String,
        type: PRType,
        value: Double,
        weight: Double,
        reps: Int,
        date: Date = .now
    ) {
        self.id = id
        self.exerciseID = exerciseID
        self.exerciseName = exerciseName
        self.typeRaw = type.rawValue
        self.value = value
        self.weight = weight
        self.reps = reps
        self.date = date
    }

    var type: PRType {
        get { PRType(rawValue: typeRaw) ?? .maxWeight }
        set { typeRaw = newValue.rawValue }
    }
}
