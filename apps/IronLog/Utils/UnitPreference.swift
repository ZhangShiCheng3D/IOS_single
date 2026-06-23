//
//  UnitPreference.swift
//  IronLog
//
//  重量单位偏好（公斤 / 磅）。数据库统一以公斤存储，显示时换算。
//

import Foundation

enum WeightUnit: String, CaseIterable, Identifiable {
    case kg
    case lb

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .kg: return "kg"
        case .lb: return "lb"
        }
    }

    /// 1 kg = 2.2046226218 lb
    private static let lbPerKg = 2.2046226218

    /// 将内部公斤值换算为该单位的显示值。
    func display(fromKg kg: Double) -> Double {
        switch self {
        case .kg: return kg
        case .lb: return kg * Self.lbPerKg
        }
    }

    /// 将该单位的输入值换算回内部公斤值。
    func toKg(_ value: Double) -> Double {
        switch self {
        case .kg: return value
        case .lb: return value / Self.lbPerKg
        }
    }

    /// 常用增减步进（kg / lb 各自符合杠铃片习惯）。
    var increment: Double {
        switch self {
        case .kg: return 2.5
        case .lb: return 5.0
        }
    }

    /// 当前用户偏好单位。供无法注入 AppSettings 的场景（如通知文案）读取。
    /// key 须与 AppSettings.Key.weightUnit 保持一致。
    static var preferred: WeightUnit {
        let raw = UserDefaults.standard.string(forKey: "settings.weightUnit") ?? WeightUnit.kg.rawValue
        return WeightUnit(rawValue: raw) ?? .kg
    }
}
