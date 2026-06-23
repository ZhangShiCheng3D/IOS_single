//
//  Haptics.swift
//  IronLog
//
//  触觉反馈的统一入口。关键操作（完成组、开始/结束训练、达成 PR）都应给出
//  恰当的物理反馈——这是「手感」品质的一部分。非 iOS 平台编译为空操作。
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

enum Haptics {
    #if os(iOS)
    /// 轻/中/重击打反馈（默认中等）。
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    /// 成功通知反馈（完成训练、破纪录等正向事件）。
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    /// 警示通知反馈（放弃训练等需要谨慎的操作）。
    static func warning() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }
    #else
    static func impact() {}
    static func success() {}
    static func warning() {}
    #endif
}
