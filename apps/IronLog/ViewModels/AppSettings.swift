//
//  AppSettings.swift
//  IronLog
//
//  全局用户偏好（单位、默认休息时长等），以 @Published 暴露、didSet 落盘 UserDefaults。
//  注意：不直接在 ObservableObject 中用 @AppStorage——那样不会触发 objectWillChange，
//  跨页面显示（如重量单位切换）不会刷新。
//

import SwiftUI

@MainActor
final class AppSettings: ObservableObject {

    /// 免费版可保存的训练次数上限；超过则引导购买。
    static let freeWorkoutLimit = 5

    private let defaults = UserDefaults.standard
    private enum Key {
        static let weightUnit = "settings.weightUnit"
        static let defaultRest = "settings.defaultRest"
        static let autoStartRest = "settings.autoStartRest"
        static let syncHealthKit = "settings.syncHealthKit"
    }

    @Published var weightUnit: WeightUnit {
        didSet { defaults.set(weightUnit.rawValue, forKey: Key.weightUnit) }
    }
    @Published var defaultRestSeconds: Int {
        didSet { defaults.set(defaultRestSeconds, forKey: Key.defaultRest) }
    }
    @Published var autoStartRestTimer: Bool {
        didSet { defaults.set(autoStartRestTimer, forKey: Key.autoStartRest) }
    }
    @Published var syncToHealthKit: Bool {
        didSet { defaults.set(syncToHealthKit, forKey: Key.syncHealthKit) }
    }

    init() {
        let unitRaw = defaults.string(forKey: Key.weightUnit) ?? WeightUnit.kg.rawValue
        weightUnit = WeightUnit(rawValue: unitRaw) ?? .kg
        // 首次启动 object(forKey:) 为 nil → 用默认 90s / 自动开启。
        defaultRestSeconds = defaults.object(forKey: Key.defaultRest) as? Int ?? 90
        autoStartRestTimer = defaults.object(forKey: Key.autoStartRest) as? Bool ?? true
        syncToHealthKit = defaults.bool(forKey: Key.syncHealthKit)
    }
}
