//
//  WaterViewModel.swift
//  FastFlow
//
//  喝水追踪逻辑：记录饮水、计算每日进度、可选同步 HealthKit。
//

import Foundation
import SwiftData
import Observation

@Observable
@MainActor
final class WaterViewModel {
    private let context: ModelContext

    /// 每日饮水目标（毫升），持久化于 UserDefaults。
    var dailyGoalML: Int {
        didSet { UserDefaults.standard.set(dailyGoalML, forKey: Self.goalKey) }
    }

    /// 是否将饮水同步到 HealthKit。
    var syncToHealth: Bool {
        didSet { UserDefaults.standard.set(syncToHealth, forKey: Self.syncKey) }
    }

    private static let goalKey = "fastflow.water.dailyGoal"
    private static let syncKey = "fastflow.water.syncHealth"
    static let defaultGoalML = 2000

    init(context: ModelContext) {
        self.context = context
        let savedGoal = UserDefaults.standard.integer(forKey: Self.goalKey)
        self.dailyGoalML = savedGoal > 0 ? savedGoal : Self.defaultGoalML
        self.syncToHealth = UserDefaults.standard.bool(forKey: Self.syncKey)
    }

    // 注：今日记录与进度的派生计算已移至 WaterTrackingView，由 @Query 驱动，
    //     增删后自动刷新；此处仅保留写入相关操作。

    // MARK: - 操作

    /// 添加一条饮水记录。
    func addWater(_ amountML: Int) {
        guard amountML > 0 else { return }
        let entry = WaterEntry(amountML: amountML)
        context.insert(entry)
        try? context.save()
        Haptics.tap()

        if syncToHealth {
            Task { await HealthKitManager.shared.saveWater(milliliters: amountML) }
        }
    }

    /// 删除一条饮水记录。
    func delete(_ entry: WaterEntry) {
        context.delete(entry)
        try? context.save()
    }
}
