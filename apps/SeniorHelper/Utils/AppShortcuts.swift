//
//  AppShortcuts.swift
//  SeniorHelper
//
//  Siri 快捷指令集成（App Intents，iOS 16+）。
//  让用户对 Siri 说「打开放大镜」「用药提醒」即可直达功能。
//

import AppIntents
import Foundation

/// App 内用于跳转标签页的通知。ContentView 监听后切换 TabView。
extension Notification.Name {
    static let switchToTab = Notification.Name("SeniorHelper.switchToTab")
}

/// 目标标签标识，随通知 userInfo 传递。
enum ShortcutTarget: String {
    static let key = "target"
    case magnifier
    case medication
}

// MARK: - 打开放大镜

struct OpenMagnifierIntent: AppIntent {
    static var title: LocalizedStringResource = "打开放大镜"
    static var description = IntentDescription("快速打开放大镜，看清小字。")

    /// 运行时把 App 切到前台。
    static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        NotificationCenter.default.post(
            name: .switchToTab,
            object: nil,
            userInfo: [ShortcutTarget.key: ShortcutTarget.magnifier.rawValue]
        )
        return .result()
    }
}

// MARK: - 打开用药提醒

struct OpenMedicationIntent: AppIntent {
    static var title: LocalizedStringResource = "查看用药提醒"
    static var description = IntentDescription("快速查看今天的用药提醒。")

    static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        NotificationCenter.default.post(
            name: .switchToTab,
            object: nil,
            userInfo: [ShortcutTarget.key: ShortcutTarget.medication.rawValue]
        )
        return .result()
    }
}

// MARK: - 快捷指令短语

/// 向系统注册可用的 Siri 短语。安装后自动出现在「快捷指令」App。
struct SeniorHelperShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: OpenMagnifierIntent(),
            phrases: [
                "用\(.applicationName)打开放大镜",
                "\(.applicationName)放大镜",
                "打开\(.applicationName)放大镜"
            ],
            shortTitle: "放大镜",
            systemImageName: "magnifyingglass"
        )
        AppShortcut(
            intent: OpenMedicationIntent(),
            phrases: [
                "用\(.applicationName)查看用药提醒",
                "\(.applicationName)用药提醒",
                "我的\(.applicationName)用药提醒"
            ],
            shortTitle: "用药提醒",
            systemImageName: "pills"
        )
    }
}
