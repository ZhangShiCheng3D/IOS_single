//
//  GameType.swift
//  PaperGames
//
//  游戏种类与难度等级的领域模型定义。
//

import SwiftUI

/// App 内提供的游戏类型。
enum GameType: String, CaseIterable, Identifiable, Codable {
    case sudoku          // 数独
    case ticTacToe       // 井字棋（经典纸笔游戏）

    var id: String { rawValue }

    /// 本地化标题键。
    var titleKey: LocalizedStringKey {
        switch self {
        case .sudoku:    return "game.sudoku.title"
        case .ticTacToe: return "game.tictactoe.title"
        }
    }

    /// 本地化副标题键。
    var subtitleKey: LocalizedStringKey {
        switch self {
        case .sudoku:    return "game.sudoku.subtitle"
        case .ticTacToe: return "game.tictactoe.subtitle"
        }
    }

    /// SF Symbol 图标名称。
    var symbol: String {
        switch self {
        case .sudoku:    return "square.grid.3x3.fill"
        case .ticTacToe: return "number.square.fill"
        }
    }

    /// 卡片主题色。
    var accent: Color {
        switch self {
        case .sudoku:    return .appAccent
        case .ticTacToe: return .appSecondary
        }
    }

    /// 是否为高级（付费解锁）玩法。
    /// 数独本体免费（含简单/中等难度），井字棋为解锁内容之一。
    var isPremiumGame: Bool {
        switch self {
        case .sudoku:    return false
        case .ticTacToe: return true
        }
    }
}

/// 数独难度等级。数值越低表示初始提示数字越少、越难。
enum Difficulty: String, CaseIterable, Identifiable, Codable {
    case easy     // 简单
    case medium   // 中等
    case hard     // 困难
    case hell     // 地狱

    var id: String { rawValue }

    /// 本地化标题键。
    var titleKey: LocalizedStringKey {
        switch self {
        case .easy:   return "difficulty.easy"
        case .medium: return "difficulty.medium"
        case .hard:   return "difficulty.hard"
        case .hell:   return "difficulty.hell"
        }
    }

    /// 生成谜题时保留的提示数字（线索）数量目标。
    /// 81 格中保留越少越难。最难仍保证 ≥17（数独唯一解最小线索数）。
    var clueCount: Int {
        switch self {
        case .easy:   return 42
        case .medium: return 34
        case .hard:   return 28
        case .hell:   return 24
        }
    }

    /// 难度强度（用于进度条等 UI 展示，0...1）。
    var intensity: Double {
        switch self {
        case .easy:   return 0.25
        case .medium: return 0.5
        case .hard:   return 0.75
        case .hell:   return 1.0
        }
    }

    /// 配色。
    var color: Color {
        switch self {
        case .easy:   return .green
        case .medium: return .blue
        case .hard:   return .orange
        case .hell:   return .red
        }
    }

    /// 是否需要付费解锁（简单/中等免费，困难/地狱付费）。
    var isPremium: Bool {
        switch self {
        case .easy, .medium: return false
        case .hard, .hell:   return true
        }
    }
}
