//
//  SavedRecipe.swift
//  BakeCalc
//
//  SwiftData 持久化模型：用户保存并命名的配方。
//

import Foundation
import SwiftData

@Model
final class SavedRecipe {
    /// 配方名称。
    var name: String
    /// 配方原始份数（用于缩放基准）。
    var baseServings: Int
    /// 备注。
    var notes: String
    /// 创建时间。
    var createdAt: Date
    /// 最近更新时间。
    var updatedAt: Date

    /// 原料明细。删除配方时级联删除其原料。
    @Relationship(deleteRule: .cascade, inverse: \SavedIngredient.recipe)
    var ingredients: [SavedIngredient]

    init(
        name: String,
        baseServings: Int = 1,
        notes: String = "",
        createdAt: Date = .now,
        updatedAt: Date = .now,
        ingredients: [SavedIngredient] = []
    ) {
        self.name = name
        self.baseServings = max(1, baseServings)
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.ingredients = ingredients
    }
}

extension SavedRecipe {
    /// 原料数量（用于列表副标题）。
    var ingredientCount: Int { ingredients.count }
}
