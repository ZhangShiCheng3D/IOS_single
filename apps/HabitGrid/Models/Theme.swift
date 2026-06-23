//
//  Theme.swift
//  HabitGrid
//
//  配色方案定义与全局主题管理。
//

import SwiftUI
import Observation

/// 一套热力图配色方案。包含 4 级浓度色 + 强调色 + 空格子色。
struct ColorPalette: Identifiable, Hashable {
    let id: String
    let nameKey: LocalizedStringKey
    /// 从浅到深的 4 个等级颜色（hex），index 0 = intensity 1 ... index 3 = intensity 4。
    let levels: [String]
    /// 强调色（按钮、tint）。
    let accentHex: String
    /// 是否为付费主题。
    let isPremium: Bool

    var accent: Color { Color(hex: accentHex) ?? .green }

    /// 空格子（未打卡）的颜色，随深浅模式自适应。
    func emptyColor(for scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(white: 0.16)
            : Color(white: 0.92)
    }

    /// 根据强度（0 = 空，1...4）返回热力图格子颜色。
    func heatColor(intensity: Int, scheme: ColorScheme) -> Color {
        guard intensity >= 1 else { return emptyColor(for: scheme) }
        let idx = min(intensity, levels.count) - 1
        return Color(hex: levels[idx]) ?? accent
    }
}

extension ColorPalette {
    /// 所有内置配色方案。前 2 套免费，其余为付费主题。
    static let all: [ColorPalette] = [
        ColorPalette(
            id: "github",
            nameKey: "theme.github",
            levels: ["#9BE9A8", "#40C463", "#30A14E", "#216E39"],
            accentHex: "#39D353",
            isPremium: false
        ),
        ColorPalette(
            id: "midnight",
            nameKey: "theme.midnight",
            levels: ["#1E3A8A", "#2563EB", "#3B82F6", "#60A5FA"],
            accentHex: "#3B82F6",
            isPremium: false
        ),
        ColorPalette(
            id: "sunset",
            nameKey: "theme.sunset",
            levels: ["#FED7AA", "#FB923C", "#F97316", "#EA580C"],
            accentHex: "#F97316",
            isPremium: true
        ),
        ColorPalette(
            id: "sakura",
            nameKey: "theme.sakura",
            levels: ["#FBCFE8", "#F472B6", "#EC4899", "#BE185D"],
            accentHex: "#EC4899",
            isPremium: true
        ),
        ColorPalette(
            id: "ocean",
            nameKey: "theme.ocean",
            levels: ["#A7F3D0", "#34D399", "#10B981", "#047857"],
            accentHex: "#10B981",
            isPremium: true
        ),
        ColorPalette(
            id: "grape",
            nameKey: "theme.grape",
            levels: ["#DDD6FE", "#A78BFA", "#8B5CF6", "#6D28D9"],
            accentHex: "#8B5CF6",
            isPremium: true
        ),
        ColorPalette(
            id: "mono",
            nameKey: "theme.mono",
            levels: ["#C9CCD1", "#9199A1", "#5B636B", "#2D333B"],
            accentHex: "#57606A",
            isPremium: true
        )
    ]

    static let `default` = all[0]

    static func palette(for id: String) -> ColorPalette {
        all.first { $0.id == id } ?? .default
    }
}

/// 外观偏好。
enum AppearancePreference: Int, CaseIterable, Identifiable {
    case system, light, dark
    var id: Int { rawValue }

    var displayName: LocalizedStringKey {
        switch self {
        case .system: return "appearance.system"
        case .light:  return "appearance.light"
        case .dark:   return "appearance.dark"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }
}

/// 全局主题管理：持久化用户选择的配色方案与外观偏好。
@Observable
final class ThemeManager {
    /// 当前选中的配色方案 id。
    var paletteID: String {
        didSet { UserDefaults.standard.set(paletteID, forKey: Keys.palette) }
    }

    /// 外观偏好。
    var appearance: AppearancePreference {
        didSet { UserDefaults.standard.set(appearance.rawValue, forKey: Keys.appearance) }
    }

    private enum Keys {
        static let palette = "habitgrid.theme.palette"
        static let appearance = "habitgrid.theme.appearance"
    }

    init() {
        let savedPalette = UserDefaults.standard.string(forKey: Keys.palette) ?? ColorPalette.default.id
        self.paletteID = savedPalette
        let rawAppearance = UserDefaults.standard.integer(forKey: Keys.appearance)
        self.appearance = AppearancePreference(rawValue: rawAppearance) ?? .system
    }

    var palette: ColorPalette {
        ColorPalette.palette(for: paletteID)
    }

    var colorSchemeOverride: ColorScheme? {
        appearance.colorScheme
    }
}
