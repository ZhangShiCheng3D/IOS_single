//
//  StoreConfig.swift
//  BakeCalc
//
//  内购配置。买断制：单一非消耗型产品解锁全部高级功能。
//  在 App Store Connect 创建对应产品，并在本地 .storekit 测试文件中配置同 ID。
//

import Foundation

enum StoreConfig {
    /// 非消耗型「专业版」解锁产品 ID。
    static let proProductID = "com.indie.bakecalc.pro"

    /// 所有需要向 App Store 查询的产品 ID 集合。
    static let allProductIDs: Set<String> = [proProductID]

    /// 本地解锁状态在 UserDefaults 中的键（作为离线兜底缓存）。
    static let unlockedDefaultsKey = "bakecalc.pro.unlocked"
}

/// 应用功能枚举：标记哪些功能需要专业版。
enum AppFeature: String, CaseIterable {
    case unitConversion      // 单位换算 —— 免费
    case temperature         // 温度换算 —— 免费
    case ovenReference       // 烤箱对照 —— 免费
    case recipeScaling       // 配方缩放 —— 专业
    case densityTable        // 原料密度表 —— 专业
    case savedRecipes        // 配方保存 —— 专业
    case panConversion       // 模具换算 —— 专业
    case eggConversion       // 鸡蛋换算 —— 专业

    /// 该功能是否需要专业版解锁。
    var requiresPro: Bool {
        switch self {
        case .unitConversion, .temperature, .ovenReference:
            return false
        case .recipeScaling, .densityTable, .savedRecipes, .panConversion, .eggConversion:
            return true
        }
    }
}
