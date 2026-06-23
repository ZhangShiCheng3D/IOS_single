//
//  RecipeScalingViewModel.swift
//  BakeCalc
//
//  配方缩放 ViewModel。按份数比例（目标份数 / 原始份数）整体缩放原料用量，
//  支持任意单位（以原始输入单位等比例换算）。
//

import Foundation

/// 编辑中的单条原料（缩放器内部使用，非持久化）。
struct ScalableIngredient: Identifiable, Equatable {
    let id = UUID()
    var name: String
    var amountText: String   // 用户输入的数量文本
    var unitLabel: String    // 自由文本单位（克 / 杯 / 个 ...）

    var amount: Double? { NumberFormatting.parse(amountText) }
}

final class RecipeScalingViewModel: ObservableObject {

    @Published var baseServingsText: String = "4"
    @Published var targetServingsText: String = "6"
    @Published var ingredients: [ScalableIngredient] = [
        .init(name: NSLocalizedString("scale.sample.flour", comment: ""), amountText: "200", unitLabel: "g"),
        .init(name: NSLocalizedString("scale.sample.sugar", comment: ""), amountText: "100", unitLabel: "g"),
        .init(name: NSLocalizedString("scale.sample.egg", comment: ""),   amountText: "2",   unitLabel: "")
    ]

    /// 缩放倍率（目标 / 原始）。无效时返回 nil。
    var factor: Double? {
        guard let base = NumberFormatting.parse(baseServingsText), base > 0,
              let target = NumberFormatting.parse(targetServingsText), target > 0 else {
            return nil
        }
        return target / base
    }

    /// 倍率显示文本，如 "×1.5"。
    var factorText: String {
        guard let factor else { return "—" }
        return "×" + NumberFormatting.formatted(factor, maxFraction: 2)
    }

    /// 计算某条原料缩放后的数量文本。
    func scaledAmount(for ingredient: ScalableIngredient) -> String {
        guard let factor, let amount = ingredient.amount else { return "—" }
        return (amount * factor).bcSmart
    }

    // MARK: - 编辑操作

    func addIngredient() {
        ingredients.append(.init(name: "", amountText: "", unitLabel: ""))
    }

    func removeIngredients(at offsets: IndexSet) {
        ingredients.remove(atOffsets: offsets)
    }

    func moveIngredients(from source: IndexSet, to destination: Int) {
        ingredients.move(fromOffsets: source, toOffset: destination)
    }
}
