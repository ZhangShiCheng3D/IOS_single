//
//  UnitConversionViewModel.swift
//  BakeCalc
//
//  单位换算 ViewModel。支持重量↔重量、体积↔体积，以及借助原料密度的
//  体积↔重量交叉换算。
//

import Foundation
import Combine

/// 换算模式。
enum ConversionMode: String, CaseIterable, Identifiable {
    case weight          // 重量 ↔ 重量
    case volume          // 体积 ↔ 体积
    case volumeToWeight  // 体积 → 重量（需密度）

    var id: String { rawValue }

    var localizedKey: String {
        switch self {
        case .weight:         return "convert.mode.weight"
        case .volume:         return "convert.mode.volume"
        case .volumeToWeight: return "convert.mode.cross"
        }
    }
}

final class UnitConversionViewModel: ObservableObject {

    @Published var mode: ConversionMode = .weight
    @Published var inputText: String = "100"

    // 重量模式
    @Published var fromWeight: WeightUnit = .gram
    @Published var toWeight: WeightUnit = .ounce

    // 体积模式
    @Published var fromVolume: VolumeUnit = .cup
    @Published var toVolume: VolumeUnit = .milliliter

    // 交叉模式：体积 → 重量
    @Published var crossFromVolume: VolumeUnit = .cup
    @Published var crossToWeight: WeightUnit = .gram
    @Published var selectedIngredientID: String = BakingData.ingredients.first?.id ?? "water"

    /// 当前选中的原料密度（交叉模式用）。
    var selectedIngredient: IngredientDensity? {
        BakingData.ingredient(id: selectedIngredientID)
    }

    /// 解析后的输入值。
    var inputValue: Double? {
        NumberFormatting.parse(inputText)
    }

    /// 换算结果。
    var result: Double? {
        guard let value = inputValue else { return nil }
        switch mode {
        case .weight:
            return UnitConverter.convertWeight(value, from: fromWeight, to: toWeight)
        case .volume:
            return UnitConverter.convertVolume(value, from: fromVolume, to: toVolume)
        case .volumeToWeight:
            let density = selectedIngredient?.gramsPerMilliliter ?? BakingData.defaultDensity
            return UnitConverter.volumeToWeight(value, from: crossFromVolume, to: crossToWeight, density: density)
        }
    }

    /// 结果展示文本。
    var resultText: String {
        guard let result else { return "—" }
        return result.bcSmart
    }

    /// 交换源/目标单位。
    func swap() {
        switch mode {
        case .weight:
            (fromWeight, toWeight) = (toWeight, fromWeight)
        case .volume:
            (fromVolume, toVolume) = (toVolume, fromVolume)
        case .volumeToWeight:
            break // 交叉模式方向固定（体积→重量）
        }
    }
}
