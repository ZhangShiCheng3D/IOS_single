//
//  LevelProgress.swift
//  LumenPuzzle
//
//  SwiftData 持久化模型：记录单个关卡的通关状态。
//

import Foundation
import SwiftData

/// 关卡进度记录。每个被玩家完成（或解锁过）的关卡对应一条记录。
@Model
final class LevelProgress {

    /// 关卡唯一标识（对应 `Level.id`）。
    @Attribute(.unique) var levelID: Int

    /// 是否已通关。
    var isCompleted: Bool

    /// 首次通关耗时（秒）。未通关为 nil。
    var bestTimeSeconds: Double?

    /// 完成所用的最少移动步数（拖动结束计一次）。未通关为 nil。
    var fewestMoves: Int?

    /// 最近一次更新时间。
    var updatedAt: Date

    init(
        levelID: Int,
        isCompleted: Bool = false,
        bestTimeSeconds: Double? = nil,
        fewestMoves: Int? = nil,
        updatedAt: Date = .now
    ) {
        self.levelID = levelID
        self.isCompleted = isCompleted
        self.bestTimeSeconds = bestTimeSeconds
        self.fewestMoves = fewestMoves
        self.updatedAt = updatedAt
    }

    /// 用一次新的通关结果更新记录，仅在更优时覆盖最佳成绩。
    func registerCompletion(timeSeconds: Double, moves: Int) {
        isCompleted = true
        if let best = bestTimeSeconds {
            bestTimeSeconds = min(best, timeSeconds)
        } else {
            bestTimeSeconds = timeSeconds
        }
        if let least = fewestMoves {
            fewestMoves = min(least, moves)
        } else {
            fewestMoves = moves
        }
        updatedAt = .now
    }
}
