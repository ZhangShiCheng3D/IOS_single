//
//  Haptics.swift
//  BakeCalc
//
//  轻量触觉反馈封装。集中管理，保证全 App 反馈一致、易于复用到矩阵内其他产品。
//  各方法为非隔离静态函数，内部统一切到主线程触发，可从任意上下文安全调用，
//  避免在 Swift 6 严格并发下与 View 的隔离规则冲突。
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

enum Haptics {

    /// 轻触：用于普通按钮、交换、切换等即时操作。
    static func tap() {
        #if canImport(UIKit)
        Task { @MainActor in
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
        #endif
    }

    /// 选择变化：用于在多个选项间切换（如选规格、选档位）。
    static func selection() {
        #if canImport(UIKit)
        Task { @MainActor in
            UISelectionFeedbackGenerator().selectionChanged()
        }
        #endif
    }

    /// 成功：用于购买完成、保存成功。
    static func success() {
        #if canImport(UIKit)
        Task { @MainActor in
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
        #endif
    }

    /// 警告：用于删除等需要注意的操作。
    static func warning() {
        #if canImport(UIKit)
        Task { @MainActor in
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        }
        #endif
    }

    /// 失败：用于保存 / 购买失败。
    static func error() {
        #if canImport(UIKit)
        Task { @MainActor in
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
        #endif
    }
}
