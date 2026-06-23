//
//  Achievement.swift
//  LumenPuzzle
//
//  成就定义（值类型，内置常量）。解锁状态由 AchievementRecord 持久化。
//

import Foundation

/// 游戏内成就。`rawValue` 即为持久化标识。
enum Achievement: String, CaseIterable, Identifiable {

    /// 完成第一关。
    case firstLight = "first_light"
    /// 完成全部 10 关。
    case enlightened = "enlightened"
    /// 在不超过 3 步内完成任意一关。
    case minimalist = "minimalist"
    /// 在 20 秒内完成任意一关。
    case swiftSolver = "swift_solver"
    /// 完成所有「困难」难度关卡。
    case shadowMaster = "shadow_master"

    var id: String { rawValue }

    /// 本地化标题键。
    var titleKey: String { "achievement.\(rawValue).title" }

    /// 本地化描述键。
    var detailKey: String { "achievement.\(rawValue).detail" }

    /// SF Symbol 图标名。
    var symbolName: String {
        switch self {
        case .firstLight:   return "sun.min.fill"
        case .enlightened:  return "sun.max.fill"
        case .minimalist:   return "scribble.variable"
        case .swiftSolver:  return "bolt.fill"
        case .shadowMaster: return "moon.stars.fill"
        }
    }
}
