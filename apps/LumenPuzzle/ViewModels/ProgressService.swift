//
//  ProgressService.swift
//  LumenPuzzle
//
//  关卡进度与成就的读写服务（封装 SwiftData 查询）。
//  设计为无状态工具：每个方法显式接收 ModelContext，便于在任意视图中复用与测试。
//

import Foundation
import SwiftData

@MainActor
struct ProgressService {

    let context: ModelContext

    // MARK: - 关卡进度

    /// 读取（或创建）某关卡的进度记录。
    func progress(for levelID: Int) -> LevelProgress {
        let descriptor = FetchDescriptor<LevelProgress>(
            predicate: #Predicate { $0.levelID == levelID }
        )
        if let existing = try? context.fetch(descriptor).first {
            return existing
        }
        let created = LevelProgress(levelID: levelID)
        context.insert(created)
        return created
    }

    /// 某关卡是否已通关。
    func isCompleted(_ levelID: Int) -> Bool {
        let descriptor = FetchDescriptor<LevelProgress>(
            predicate: #Predicate { $0.levelID == levelID && $0.isCompleted }
        )
        return ((try? context.fetchCount(descriptor)) ?? 0) > 0
    }

    /// 关卡是否已解锁。规则：第 1 关永远解锁；其余需前一关通关。
    func isUnlocked(_ levelID: Int) -> Bool {
        guard levelID > 1 else { return true }
        return isCompleted(levelID - 1)
    }

    /// 已通关关卡总数。
    func completedCount() -> Int {
        let descriptor = FetchDescriptor<LevelProgress>(
            predicate: #Predicate { $0.isCompleted }
        )
        return (try? context.fetchCount(descriptor)) ?? 0
    }

    /// 记录一次通关，返回本次"新解锁"的成就列表。
    @discardableResult
    func recordCompletion(level: Level, timeSeconds: Double, moves: Int) -> [Achievement] {
        let record = progress(for: level.id)
        record.registerCompletion(timeSeconds: timeSeconds, moves: moves)
        try? context.save()
        return evaluateAchievements(justCompleted: level, timeSeconds: timeSeconds, moves: moves)
    }

    // MARK: - 成就

    /// 已解锁成就集合。
    func unlockedAchievements() -> Set<Achievement> {
        let records = (try? context.fetch(FetchDescriptor<AchievementRecord>())) ?? []
        return Set(records.compactMap { Achievement(rawValue: $0.identifier) })
    }

    /// 某成就是否已解锁。
    func isUnlocked(_ achievement: Achievement) -> Bool {
        let id = achievement.rawValue
        let descriptor = FetchDescriptor<AchievementRecord>(
            predicate: #Predicate { $0.identifier == id }
        )
        return ((try? context.fetchCount(descriptor)) ?? 0) > 0
    }

    /// 解锁一个成就（幂等）。
    private func unlock(_ achievement: Achievement) -> Bool {
        guard !isUnlocked(achievement) else { return false }
        context.insert(AchievementRecord(identifier: achievement.rawValue))
        return true
    }

    /// 根据本次通关与全局进度评估并解锁成就，返回新解锁项。
    private func evaluateAchievements(
        justCompleted level: Level,
        timeSeconds: Double,
        moves: Int
    ) -> [Achievement] {
        var newlyUnlocked: [Achievement] = []

        if level.id == 1, unlock(.firstLight) {
            newlyUnlocked.append(.firstLight)
        }
        if moves <= 3, unlock(.minimalist) {
            newlyUnlocked.append(.minimalist)
        }
        if timeSeconds <= 20, unlock(.swiftSolver) {
            newlyUnlocked.append(.swiftSolver)
        }

        // 全通关。
        if completedCount() >= LevelCatalog.count, unlock(.enlightened) {
            newlyUnlocked.append(.enlightened)
        }

        // 困难全通。
        let hardIDs = LevelCatalog.all.filter { $0.difficulty == .hard }.map(\.id)
        if hardIDs.allSatisfy({ isCompleted($0) }), unlock(.shadowMaster) {
            newlyUnlocked.append(.shadowMaster)
        }

        if !newlyUnlocked.isEmpty {
            try? context.save()
        }
        return newlyUnlocked
    }
}
