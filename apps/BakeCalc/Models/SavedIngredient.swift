//
//  SavedIngredient.swift
//  BakeCalc
//
//  SwiftData 持久化模型：配方中的单条原料。
//  以「克」存储基准重量，便于按份数比例无损缩放。
//

import Foundation
import SwiftData

@Model
final class SavedIngredient {
    /// 原料名称（用户自由输入）。
    var name: String
    /// 基准重量（克），对应配方 baseServings 份。
    var grams: Double
    /// 排序序号。
    var order: Int

    /// 反向关系：所属配方。
    var recipe: SavedRecipe?

    init(name: String, grams: Double, order: Int = 0, recipe: SavedRecipe? = nil) {
        self.name = name
        self.grams = max(0, grams)
        self.order = order
        self.recipe = recipe
    }
}
