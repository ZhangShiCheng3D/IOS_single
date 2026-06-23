//
//  BakingData.swift
//  BakeCalc
//
//  静态烘焙参数表：原料密度、烤箱温度对照、模具尺寸、鸡蛋重量。
//  数据来源于通用烘焙资料（USDA / King Arthur Baking 等公开换算表），
//  以「克 / 毫升」为统一密度单位。这些是只读参考数据，不进入 SwiftData。
//

import Foundation

// MARK: - 原料密度

/// 单一烘焙原料的密度参数。
struct IngredientDensity: Identifiable, Hashable {
    let id: String                 // 稳定标识符
    let nameKey: String            // 本地化名称键
    let category: IngredientCategory
    let gramsPerMilliliter: Double // 密度 g/mL

    /// 1 美制 cup（236.59 mL）约等于多少克，便于直观展示。
    var gramsPerCup: Double {
        gramsPerMilliliter * VolumeUnit.cup.millilitersPerUnit
    }

    /// 1 大勺（tbsp）约等于多少克。
    var gramsPerTablespoon: Double {
        gramsPerMilliliter * VolumeUnit.tablespoon.millilitersPerUnit
    }
}

/// 原料分类。
enum IngredientCategory: String, CaseIterable, Identifiable {
    case flour
    case sugar
    case fat
    case liquid
    case other

    var id: String { rawValue }

    var localizedKey: String {
        switch self {
        case .flour:  return "category.flour"
        case .sugar:  return "category.sugar"
        case .fat:    return "category.fat"
        case .liquid: return "category.liquid"
        case .other:  return "category.other"
        }
    }

    var systemImage: String {
        switch self {
        case .flour:  return "fork.knife"
        case .sugar:  return "cube"
        case .fat:    return "drop.fill"
        case .liquid: return "drop"
        case .other:  return "leaf"
        }
    }
}

// MARK: - 烤箱温度对照

/// 烤箱温度档位（摄氏 / 华氏 / 英式 Gas Mark / 描述）。
struct OvenReference: Identifiable, Hashable {
    let id = UUID()
    let celsius: Int
    let fahrenheit: Int
    let gasMark: String
    let descriptionKey: String
}

// MARK: - 模具

/// 模具形状。
enum PanShape: String, CaseIterable, Identifiable {
    case round
    case square
    case rectangle

    var id: String { rawValue }

    var localizedKey: String {
        switch self {
        case .round:     return "pan.round"
        case .square:    return "pan.square"
        case .rectangle: return "pan.rectangle"
        }
    }

    var systemImage: String {
        switch self {
        case .round:     return "circle"
        case .square:    return "square"
        case .rectangle: return "rectangle"
        }
    }
}

/// 一个模具的尺寸定义（单位：厘米）。
struct PanSize: Identifiable, Hashable {
    let id = UUID()
    let shape: PanShape
    let nameKey: String
    /// 圆模为直径；方/矩形为长。单位 cm。
    let dimensionA: Double
    /// 矩形为宽；圆/方时与 A 相同或忽略。单位 cm。
    let dimensionB: Double

    /// 底面积（cm²），用于按面积比例缩放配方。
    var area: Double {
        switch shape {
        case .round:
            let r = dimensionA / 2
            return Double.pi * r * r
        case .square:
            return dimensionA * dimensionA
        case .rectangle:
            return dimensionA * dimensionB
        }
    }
}

// MARK: - 鸡蛋

/// 鸡蛋规格（去壳净重，单位克）。基于 USDA 标准蛋重分级。
struct EggGrade: Identifiable, Hashable {
    let id: String
    let nameKey: String
    let wholeGrams: Double   // 全蛋（去壳）
    let whiteGrams: Double   // 蛋白
    let yolkGrams: Double    // 蛋黄
}

// MARK: - 数据集合

enum BakingData {

    /// 原料密度表。
    static let ingredients: [IngredientDensity] = [
        // 面粉类
        .init(id: "ap_flour",      nameKey: "ingredient.ap_flour",      category: .flour,  gramsPerMilliliter: 0.529), // ~125 g/cup
        .init(id: "bread_flour",   nameKey: "ingredient.bread_flour",   category: .flour,  gramsPerMilliliter: 0.537),
        .init(id: "cake_flour",    nameKey: "ingredient.cake_flour",    category: .flour,  gramsPerMilliliter: 0.482),
        .init(id: "whole_wheat",   nameKey: "ingredient.whole_wheat",   category: .flour,  gramsPerMilliliter: 0.508),
        .init(id: "almond_flour",  nameKey: "ingredient.almond_flour",  category: .flour,  gramsPerMilliliter: 0.406),
        .init(id: "cornstarch",    nameKey: "ingredient.cornstarch",    category: .flour,  gramsPerMilliliter: 0.508),
        .init(id: "cocoa",         nameKey: "ingredient.cocoa",         category: .flour,  gramsPerMilliliter: 0.355),
        .init(id: "rolled_oats",   nameKey: "ingredient.rolled_oats",   category: .flour,  gramsPerMilliliter: 0.380),

        // 糖类
        .init(id: "granulated",    nameKey: "ingredient.granulated",    category: .sugar,  gramsPerMilliliter: 0.845), // ~200 g/cup
        .init(id: "brown_sugar",   nameKey: "ingredient.brown_sugar",   category: .sugar,  gramsPerMilliliter: 0.930), // packed
        .init(id: "powdered",      nameKey: "ingredient.powdered",      category: .sugar,  gramsPerMilliliter: 0.508),
        .init(id: "honey",         nameKey: "ingredient.honey",         category: .liquid, gramsPerMilliliter: 1.420),
        .init(id: "maple_syrup",   nameKey: "ingredient.maple_syrup",   category: .liquid, gramsPerMilliliter: 1.370),

        // 油脂类
        .init(id: "butter",        nameKey: "ingredient.butter",        category: .fat,    gramsPerMilliliter: 0.959), // ~227 g/cup
        .init(id: "veg_oil",       nameKey: "ingredient.veg_oil",       category: .fat,    gramsPerMilliliter: 0.918),

        // 液体类
        .init(id: "water",         nameKey: "ingredient.water",         category: .liquid, gramsPerMilliliter: 1.000),
        .init(id: "whole_milk",    nameKey: "ingredient.whole_milk",    category: .liquid, gramsPerMilliliter: 1.030),
        .init(id: "heavy_cream",   nameKey: "ingredient.heavy_cream",   category: .liquid, gramsPerMilliliter: 0.994),

        // 其他
        .init(id: "table_salt",    nameKey: "ingredient.table_salt",    category: .other,  gramsPerMilliliter: 1.217),
        .init(id: "baking_powder", nameKey: "ingredient.baking_powder", category: .other,  gramsPerMilliliter: 0.900),
        .init(id: "baking_soda",   nameKey: "ingredient.baking_soda",   category: .other,  gramsPerMilliliter: 0.950)
    ]

    /// 默认密度（找不到原料时用水）。
    static let defaultDensity: Double = 1.0

    /// 烤箱温度对照表。
    static let ovenReferences: [OvenReference] = [
        .init(celsius: 110, fahrenheit: 225, gasMark: "1/4", descriptionKey: "oven.very_slow"),
        .init(celsius: 120, fahrenheit: 250, gasMark: "1/2", descriptionKey: "oven.very_slow"),
        .init(celsius: 140, fahrenheit: 275, gasMark: "1",   descriptionKey: "oven.slow"),
        .init(celsius: 150, fahrenheit: 300, gasMark: "2",   descriptionKey: "oven.slow"),
        .init(celsius: 160, fahrenheit: 325, gasMark: "3",   descriptionKey: "oven.moderately_slow"),
        .init(celsius: 180, fahrenheit: 350, gasMark: "4",   descriptionKey: "oven.moderate"),
        .init(celsius: 190, fahrenheit: 375, gasMark: "5",   descriptionKey: "oven.moderately_hot"),
        .init(celsius: 200, fahrenheit: 400, gasMark: "6",   descriptionKey: "oven.hot"),
        .init(celsius: 220, fahrenheit: 425, gasMark: "7",   descriptionKey: "oven.hot"),
        .init(celsius: 230, fahrenheit: 450, gasMark: "8",   descriptionKey: "oven.very_hot"),
        .init(celsius: 240, fahrenheit: 475, gasMark: "9",   descriptionKey: "oven.very_hot")
    ]

    /// 常见模具尺寸（厘米）。
    static let panSizes: [PanSize] = [
        .init(shape: .round,     nameKey: "pansize.round_15",  dimensionA: 15, dimensionB: 15),
        .init(shape: .round,     nameKey: "pansize.round_18",  dimensionA: 18, dimensionB: 18),
        .init(shape: .round,     nameKey: "pansize.round_20",  dimensionA: 20, dimensionB: 20),
        .init(shape: .round,     nameKey: "pansize.round_23",  dimensionA: 23, dimensionB: 23),
        .init(shape: .round,     nameKey: "pansize.round_25",  dimensionA: 25, dimensionB: 25),
        .init(shape: .square,    nameKey: "pansize.square_20", dimensionA: 20, dimensionB: 20),
        .init(shape: .square,    nameKey: "pansize.square_23", dimensionA: 23, dimensionB: 23),
        .init(shape: .rectangle, nameKey: "pansize.rect_23_33", dimensionA: 23, dimensionB: 33),
        .init(shape: .rectangle, nameKey: "pansize.rect_20_30", dimensionA: 20, dimensionB: 30)
    ]

    /// 鸡蛋规格表（去壳净重）。
    static let eggGrades: [EggGrade] = [
        .init(id: "small",       nameKey: "egg.small",       wholeGrams: 38, whiteGrams: 23, yolkGrams: 13),
        .init(id: "medium",      nameKey: "egg.medium",      wholeGrams: 44, whiteGrams: 27, yolkGrams: 15),
        .init(id: "large",       nameKey: "egg.large",       wholeGrams: 50, whiteGrams: 30, yolkGrams: 17),
        .init(id: "extra_large", nameKey: "egg.extra_large", wholeGrams: 56, whiteGrams: 34, yolkGrams: 19),
        .init(id: "jumbo",       nameKey: "egg.jumbo",       wholeGrams: 63, whiteGrams: 38, yolkGrams: 21)
    ]

    /// 按 id 查找原料密度。
    static func ingredient(id: String) -> IngredientDensity? {
        ingredients.first { $0.id == id }
    }
}
