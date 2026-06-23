//
//  Exercise.swift
//  IronLog
//
//  动作模型：力量训练动作库的核心实体。
//  内置 100+ 动作，用户也可创建自定义动作。
//

import Foundation
import SwiftData

/// 肌群分类。用于动作库筛选与训练量统计。
enum MuscleGroup: String, Codable, CaseIterable, Identifiable {
    case chest          // 胸
    case back           // 背
    case shoulders      // 肩
    case biceps         // 肱二头
    case triceps        // 肱三头
    case legs           // 腿（综合）
    case quads          // 股四头
    case hamstrings     // 腘绳肌
    case glutes         // 臀
    case calves         // 小腿
    case abs            // 核心/腹
    case forearms       // 前臂
    case fullBody       // 全身
    case cardio         // 有氧

    var id: String { rawValue }

    /// 本地化显示名称的键。
    var localizedNameKey: String { "muscle.\(rawValue)" }

    /// SF Symbol 图标。
    var systemImage: String {
        switch self {
        case .chest:      return "figure.strengthtraining.traditional"
        case .back:       return "figure.rower"
        case .shoulders:  return "figure.arms.open"
        case .biceps:     return "figure.strengthtraining.functional"
        case .triceps:    return "figure.strengthtraining.functional"
        case .legs, .quads, .hamstrings, .glutes, .calves:
            return "figure.run"
        case .abs:        return "figure.core.training"
        case .forearms:   return "hand.raised"
        case .fullBody:   return "figure.mixed.cardio"
        case .cardio:     return "heart.fill"
        }
    }

    /// 用于主题着色的强调色名称（对应 Assets 中的 ColorAsset）。
    var accentColorName: String {
        switch self {
        case .chest, .shoulders, .triceps:        return "MuscleAccentRed"
        case .back, .biceps, .forearms:           return "MuscleAccentBlue"
        case .legs, .quads, .hamstrings, .glutes, .calves:
            return "MuscleAccentGreen"
        case .abs, .fullBody, .cardio:            return "MuscleAccentOrange"
        }
    }
}

/// 器械类型。
enum Equipment: String, Codable, CaseIterable, Identifiable {
    case barbell        // 杠铃
    case dumbbell       // 哑铃
    case machine        // 器械
    case cable          // 龙门/绳索
    case bodyweight     // 自重
    case kettlebell     // 壶铃
    case bands          // 弹力带
    case other          // 其他

    var id: String { rawValue }
    var localizedNameKey: String { "equipment.\(rawValue)" }
}

/// 单个训练动作。
@Model
final class Exercise {
    /// 唯一标识。内置动作使用稳定的字符串 ID，便于去重与升级。
    @Attribute(.unique) var id: String
    /// 动作名称（用户语言）。
    var name: String
    /// 英文名称，用于检索与本地化兜底。
    var nameEN: String
    /// 主要肌群（rawValue 存储，便于 SwiftData 查询）。
    var muscleGroupRaw: String
    /// 器械类型。
    var equipmentRaw: String
    /// 动作要领/说明。
    var notes: String
    /// 是否为用户自定义动作。
    var isCustom: Bool
    /// 是否被用户收藏（置顶展示）。
    var isFavorite: Bool
    /// 创建时间。
    var createdAt: Date

    /// 反向关系：使用了此动作的所有组记录。
    @Relationship(deleteRule: .nullify, inverse: \SetEntry.exercise)
    var setEntries: [SetEntry] = []

    init(
        id: String = UUID().uuidString,
        name: String,
        nameEN: String = "",
        muscleGroup: MuscleGroup,
        equipment: Equipment,
        notes: String = "",
        isCustom: Bool = false,
        isFavorite: Bool = false,
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.nameEN = nameEN.isEmpty ? name : nameEN
        self.muscleGroupRaw = muscleGroup.rawValue
        self.equipmentRaw = equipment.rawValue
        self.notes = notes
        self.isCustom = isCustom
        self.isFavorite = isFavorite
        self.createdAt = createdAt
    }

    // MARK: - 便捷计算属性

    var muscleGroup: MuscleGroup {
        get { MuscleGroup(rawValue: muscleGroupRaw) ?? .fullBody }
        set { muscleGroupRaw = newValue.rawValue }
    }

    var equipment: Equipment {
        get { Equipment(rawValue: equipmentRaw) ?? .other }
        set { equipmentRaw = newValue.rawValue }
    }
}
