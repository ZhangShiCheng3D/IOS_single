//
//  CollageEnums.swift
//  CollageKit
//
//  拼图的基础枚举：导出比例、模板分类、背景类型。
//

import SwiftUI

/// 导出画布比例。
enum AspectRatio: String, CaseIterable, Identifiable, Codable {
    case square      // 1:1
    case portrait    // 4:5
    case story       // 9:16

    var id: String { rawValue }

    /// 宽高比（width / height）。
    var ratio: CGFloat {
        switch self {
        case .square:   return 1.0
        case .portrait: return 4.0 / 5.0
        case .story:    return 9.0 / 16.0
        }
    }

    /// 在给定最大边长下计算画布像素尺寸。
    func canvasSize(maxDimension: CGFloat) -> CGSize {
        if ratio >= 1 {
            return CGSize(width: maxDimension, height: maxDimension / ratio)
        } else {
            return CGSize(width: maxDimension * ratio, height: maxDimension)
        }
    }

    var displayName: LocalizedStringKey {
        switch self {
        case .square:   return "1:1"
        case .portrait: return "4:5"
        case .story:    return "9:16"
        }
    }

    var systemImage: String {
        switch self {
        case .square:   return "square"
        case .portrait: return "rectangle.portrait"
        case .story:    return "rectangle.portrait.fill"
        }
    }
}

/// 模板分类。
enum TemplateCategory: String, CaseIterable, Identifiable, Codable {
    case grid        // 九宫格
    case magazine    // 杂志风
    case film        // 胶片风
    case freeform    // 自由

    var id: String { rawValue }

    var displayName: LocalizedStringKey {
        switch self {
        case .grid:     return "category_grid"
        case .magazine: return "category_magazine"
        case .film:     return "category_film"
        case .freeform: return "category_freeform"
        }
    }

    var systemImage: String {
        switch self {
        case .grid:     return "square.grid.3x3"
        case .magazine: return "rectangle.3.group"
        case .film:     return "film"
        case .freeform: return "scribble.variable"
        }
    }
}

/// 背景类型。
enum BackgroundKind: String, CaseIterable, Identifiable, Codable {
    case solid       // 纯色
    case gradient    // 渐变

    var id: String { rawValue }

    var displayName: LocalizedStringKey {
        switch self {
        case .solid:    return "background_solid"
        case .gradient: return "background_gradient"
        }
    }
}

/// 文字粗细。
enum TextWeight: String, CaseIterable, Identifiable, Codable {
    case regular
    case medium
    case bold
    case heavy

    var id: String { rawValue }

    var fontWeight: Font.Weight {
        switch self {
        case .regular: return .regular
        case .medium:  return .medium
        case .bold:    return .bold
        case .heavy:   return .heavy
        }
    }

    var uiFontWeight: UIFont.Weight {
        switch self {
        case .regular: return .regular
        case .medium:  return .medium
        case .bold:    return .bold
        case .heavy:   return .heavy
        }
    }
}
