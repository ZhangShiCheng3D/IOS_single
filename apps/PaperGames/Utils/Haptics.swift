//
//  Haptics.swift
//  PaperGames
//
//  轻量触觉反馈封装。集中管理避免在视图中散落 UIKit 调用。
//

import UIKit

@MainActor
enum Haptics {
    /// 全局开关，由 `SettingsStore.hapticsEnabled` 同步。
    /// 集中在此判断，确保所有触觉调用（含完成、井字棋）统一受设置控制。
    static var isEnabled = true

    /// 轻微点击反馈（选择数字、点格子）。
    static func tap() {
        guard isEnabled else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    /// 中等反馈（放置数字）。
    static func place() {
        guard isEnabled else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    /// 错误反馈。
    static func error() {
        guard isEnabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }

    /// 成功反馈（完成谜题）。
    static func success() {
        guard isEnabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}
