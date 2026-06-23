//
//  EggConversionViewModel.swift
//  BakeCalc
//
//  鸡蛋换算 ViewModel。在「鸡蛋个数」与「重量（克）」之间双向换算，
//  区分全蛋 / 蛋白 / 蛋黄，并按所选规格的净重计算。
//

import Foundation

/// 鸡蛋部位。
enum EggPart: String, CaseIterable, Identifiable {
    case whole
    case white
    case yolk

    var id: String { rawValue }

    var localizedKey: String {
        switch self {
        case .whole: return "egg.part.whole"
        case .white: return "egg.part.white"
        case .yolk:  return "egg.part.yolk"
        }
    }

    func grams(in grade: EggGrade) -> Double {
        switch self {
        case .whole: return grade.wholeGrams
        case .white: return grade.whiteGrams
        case .yolk:  return grade.yolkGrams
        }
    }
}

/// 换算方向。
enum EggDirection: String, CaseIterable, Identifiable {
    case countToWeight   // 个数 → 重量
    case weightToCount   // 重量 → 个数

    var id: String { rawValue }

    var localizedKey: String {
        switch self {
        case .countToWeight: return "egg.dir.count_to_weight"
        case .weightToCount: return "egg.dir.weight_to_count"
        }
    }
}

final class EggConversionViewModel: ObservableObject {

    @Published var direction: EggDirection = .countToWeight
    @Published var grade: EggGrade = BakingData.eggGrades.first { $0.id == "large" } ?? BakingData.eggGrades[0]
    @Published var part: EggPart = .whole
    @Published var inputText: String = "2"

    /// 单个所选部位的净重（克）。
    var unitGrams: Double {
        part.grams(in: grade)
    }

    var inputValue: Double? {
        NumberFormatting.parse(inputText)
    }

    /// 主结果数值。
    var result: Double? {
        guard let value = inputValue else { return nil }
        switch direction {
        case .countToWeight:
            return value * unitGrams
        case .weightToCount:
            guard unitGrams > 0 else { return .nan }
            return value / unitGrams
        }
    }

    var resultText: String {
        guard let result else { return "—" }
        switch direction {
        case .countToWeight: return result.bcSmart
        case .weightToCount: return NumberFormatting.formatted(result, maxFraction: 1)
        }
    }

    /// 结果单位本地化键。
    var resultUnitKey: String {
        direction == .countToWeight ? "unit.gram" : "egg.unit.count"
    }

    /// 整数个数建议（重量→个数时给出向上/向下取整提示）。
    var roundedSuggestion: (down: Int, up: Int)? {
        guard direction == .weightToCount, let result, result.isFinite, result > 0 else { return nil }
        return (Int(result.rounded(.down)), Int(result.rounded(.up)))
    }

    func toggleDirection() {
        direction = direction == .countToWeight ? .weightToCount : .countToWeight
    }
}
