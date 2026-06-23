//
//  SettingsStore.swift
//  PaperGames
//
//  全局用户设置。使用 Observation 框架的 @Observable，底层通过
//  UserDefaults 持久化（轻量偏好设置，无需 SwiftData）。
//

import SwiftUI
import Observation

/// 配色方案偏好。
enum AppColorScheme: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var titleKey: LocalizedStringKey {
        switch self {
        case .system: return "settings.appearance.system"
        case .light:  return "settings.appearance.light"
        case .dark:   return "settings.appearance.dark"
        }
    }

    /// 映射到 SwiftUI 的 ColorScheme（system 返回 nil 跟随系统）。
    var preferred: ColorScheme? {
        switch self {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }
}

@Observable
@MainActor
final class SettingsStore {

    // MARK: - 持久化键
    private enum Key {
        static let colorScheme = "settings.colorScheme"
        static let largeFont = "settings.largeFont"
        static let mistakeHighlight = "settings.mistakeHighlight"
        static let highlightPeers = "settings.highlightPeers"
        static let hapticsEnabled = "settings.haptics"
        static let autoNotesRemoval = "settings.autoNotesRemoval"
    }

    private let defaults = UserDefaults.standard

    // MARK: - 设置项

    /// 配色方案。
    var colorScheme: AppColorScheme {
        didSet { defaults.set(colorScheme.rawValue, forKey: Key.colorScheme) }
    }

    /// 大字号模式。
    var largeFont: Bool {
        didSet { defaults.set(largeFont, forKey: Key.largeFont) }
    }

    /// 错误提示开关：填入与解答冲突的数字时高亮提示。
    var mistakeHighlight: Bool {
        didSet { defaults.set(mistakeHighlight, forKey: Key.mistakeHighlight) }
    }

    /// 高亮同行/列/宫及相同数字（辅助视觉）。
    var highlightPeers: Bool {
        didSet { defaults.set(highlightPeers, forKey: Key.highlightPeers) }
    }

    /// 触觉反馈开关。同步到 `Haptics.isEnabled`，使全局触觉统一受控。
    var hapticsEnabled: Bool {
        didSet {
            defaults.set(hapticsEnabled, forKey: Key.hapticsEnabled)
            Haptics.isEnabled = hapticsEnabled
        }
    }

    /// 填入数字时自动清除相关笔记。
    var autoNotesRemoval: Bool {
        didSet { defaults.set(autoNotesRemoval, forKey: Key.autoNotesRemoval) }
    }

    init() {
        let d = UserDefaults.standard
        // 注册默认值，确保首次启动有合理初值。
        d.register(defaults: [
            Key.colorScheme: AppColorScheme.system.rawValue,
            Key.largeFont: false,
            Key.mistakeHighlight: true,
            Key.highlightPeers: true,
            Key.hapticsEnabled: true,
            Key.autoNotesRemoval: true
        ])
        colorScheme = AppColorScheme(rawValue: d.string(forKey: Key.colorScheme) ?? "") ?? .system
        largeFont = d.bool(forKey: Key.largeFont)
        mistakeHighlight = d.bool(forKey: Key.mistakeHighlight)
        highlightPeers = d.bool(forKey: Key.highlightPeers)
        hapticsEnabled = d.bool(forKey: Key.hapticsEnabled)
        autoNotesRemoval = d.bool(forKey: Key.autoNotesRemoval)
        // 首次同步全局触觉开关。
        Haptics.isEnabled = hapticsEnabled
    }
}
