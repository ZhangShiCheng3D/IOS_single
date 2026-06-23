//
//  MeasurementUnits.swift
//  BakeCalc
//
//  烘焙单位定义与换算核心。区分「重量单位」与「体积单位」。
//  体积↔重量的换算依赖原料密度（见 BakingData.ingredients）。
//

import Foundation

// MARK: - 重量单位

/// 重量单位。基准为克（g）。
enum WeightUnit: String, CaseIterable, Identifiable, Codable {
    case gram
    case kilogram
    case ounce
    case pound

    var id: String { rawValue }

    /// 1 个该单位等于多少克。
    var gramsPerUnit: Double {
        switch self {
        case .gram:     return 1
        case .kilogram: return 1000
        case .ounce:    return 28.349523125
        case .pound:    return 453.59237
        }
    }

    /// 本地化短名称键（在 Localizable.strings 中定义）。
    var localizedKey: String {
        switch self {
        case .gram:     return "unit.gram"
        case .kilogram: return "unit.kilogram"
        case .ounce:    return "unit.ounce"
        case .pound:    return "unit.pound"
        }
    }
}

// MARK: - 体积单位

/// 体积单位。基准为毫升（mL）。采用美制常用烘焙量度。
enum VolumeUnit: String, CaseIterable, Identifiable, Codable {
    case milliliter
    case liter
    case teaspoon       // tsp
    case tablespoon     // tbsp
    case cup            // 美制 1 cup
    case fluidOunce     // fl oz

    var id: String { rawValue }

    /// 1 个该单位等于多少毫升。
    var millilitersPerUnit: Double {
        switch self {
        case .milliliter: return 1
        case .liter:      return 1000
        case .teaspoon:   return 4.92892159375
        case .tablespoon: return 14.78676478125
        case .cup:        return 236.5882365
        case .fluidOunce: return 29.5735295625
        }
    }

    var localizedKey: String {
        switch self {
        case .milliliter: return "unit.milliliter"
        case .liter:      return "unit.liter"
        case .teaspoon:   return "unit.teaspoon"
        case .tablespoon: return "unit.tablespoon"
        case .cup:        return "unit.cup"
        case .fluidOunce: return "unit.fluidOunce"
        }
    }
}

// MARK: - 换算引擎

enum UnitConverter {

    /// 重量 → 重量。
    static func convertWeight(_ value: Double, from: WeightUnit, to: WeightUnit) -> Double {
        let grams = value * from.gramsPerUnit
        return grams / to.gramsPerUnit
    }

    /// 体积 → 体积。
    static func convertVolume(_ value: Double, from: VolumeUnit, to: VolumeUnit) -> Double {
        let ml = value * from.millilitersPerUnit
        return ml / to.millilitersPerUnit
    }

    /// 体积 → 重量。需要原料密度（g/mL）。
    static func volumeToWeight(_ value: Double, from: VolumeUnit, to: WeightUnit, density: Double) -> Double {
        let ml = value * from.millilitersPerUnit
        let grams = ml * density
        return grams / to.gramsPerUnit
    }

    /// 重量 → 体积。需要原料密度（g/mL）。
    static func weightToVolume(_ value: Double, from: WeightUnit, to: VolumeUnit, density: Double) -> Double {
        let grams = value * from.gramsPerUnit
        guard density > 0 else { return .nan }
        let ml = grams / density
        return ml / to.millilitersPerUnit
    }
}
