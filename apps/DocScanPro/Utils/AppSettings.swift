//
//  AppSettings.swift
//  DocScanPro
//
//  全局应用偏好设置，持久化于 UserDefaults。
//

import SwiftUI
import Combine

/// 外观模式偏好。
enum ColorSchemePreference: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    var localizedTitle: String {
        switch self {
        case .system: return NSLocalizedString("settings.appearance.system", comment: "")
        case .light: return NSLocalizedString("settings.appearance.light", comment: "")
        case .dark: return NSLocalizedString("settings.appearance.dark", comment: "")
        }
    }
}

/// 应用设置，使用 @AppStorage 背后的 UserDefaults 持久化。
final class AppSettings: ObservableObject {

    @AppStorage("colorSchemePreference") private var storedScheme: String = ColorSchemePreference.system.rawValue
    @AppStorage("autoRunOCR") var autoRunOCR: Bool = true
    @AppStorage("includeTextLayerInPDF") var includeTextLayerInPDF: Bool = true
    @AppStorage("jpegQuality") var jpegQuality: Double = 0.8

    /// 计算属性桥接 enum 与持久化字符串。
    var colorSchemePreference: ColorSchemePreference {
        get { ColorSchemePreference(rawValue: storedScheme) ?? .system }
        set {
            objectWillChange.send()
            storedScheme = newValue.rawValue
        }
    }
}
