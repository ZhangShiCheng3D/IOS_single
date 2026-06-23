//
//  GameRecord.swift
//  PaperGames
//
//  SwiftData 持久化模型：记录每一局完成的对局，用于统计与最佳成绩。
//

import Foundation
import SwiftData

/// 一条完成记录。每完成一局有效游戏写入一条。
@Model
final class GameRecord {

    /// 游戏类型原始值（GameType.rawValue）。
    var gameTypeRaw: String

    /// 难度原始值（Difficulty.rawValue）；非数独类游戏可为空。
    var difficultyRaw: String?

    /// 完成耗时（秒）。
    var durationSeconds: Int

    /// 本局发生的错误次数。
    var mistakes: Int

    /// 是否使用了笔记功能（用于成就/统计）。
    var usedNotes: Bool

    /// 完成时间。
    var completedAt: Date

    init(
        gameType: GameType,
        difficulty: Difficulty? = nil,
        durationSeconds: Int,
        mistakes: Int = 0,
        usedNotes: Bool = false,
        completedAt: Date = .now
    ) {
        self.gameTypeRaw = gameType.rawValue
        self.difficultyRaw = difficulty?.rawValue
        self.durationSeconds = durationSeconds
        self.mistakes = mistakes
        self.usedNotes = usedNotes
        self.completedAt = completedAt
    }

    /// 还原为枚举类型。
    var gameType: GameType? { GameType(rawValue: gameTypeRaw) }
    var difficulty: Difficulty? { difficultyRaw.flatMap(Difficulty.init(rawValue:)) }

    /// 格式化的耗时（mm:ss）。
    var formattedDuration: String { Self.format(seconds: durationSeconds) }

    /// 将秒数格式化为 mm:ss。
    static func format(seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%02d:%02d", m, s)
    }
}
