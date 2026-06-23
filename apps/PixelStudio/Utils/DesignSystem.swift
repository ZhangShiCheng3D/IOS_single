//
//  DesignSystem.swift
//  PixelStudio
//
//  设计令牌（间距 / 圆角）与触觉反馈集中管理。统一全局的 8pt 间距栅格与
//  圆角层级，避免散落的魔法数字；触觉反馈封装在 AppHaptics，供离散交互调用
//  （高频画布笔触不触发，以免噪音与性能损耗）。
//

import SwiftUI
import UIKit

/// 8pt 间距栅格与一致的圆角层级。
enum AppMetrics {
    /// 4pt — 紧凑内距（标签内行距）。
    static let spacingXS: CGFloat = 4
    /// 8pt — 元素间默认间距。
    static let spacingS: CGFloat = 8
    /// 12pt — 面板内距。
    static let spacingM: CGFloat = 12
    /// 16pt — 卡片 / 区块间距。
    static let spacingL: CGFloat = 16
    /// 24pt — 大区块（付费墙、空状态）间距。
    static let spacingXL: CGFloat = 24

    /// 8pt — 色块、工具按钮。
    static let radiusS: CGFloat = 8
    /// 12pt — 卡片、输入区。
    static let radiusM: CGFloat = 12
    /// 16pt — 主按钮、大容器。
    static let radiusL: CGFloat = 16
}

/// 轻量触觉反馈封装。仅用于离散用户操作（选工具、选色、撤销、增删帧/层、购买结果）。
enum AppHaptics {
    /// 选择类切换（工具、颜色、帧、图层）。
    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }

    /// 轻碰击（新增 / 切换开关）。
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }

    /// 操作成功（购买完成、导出 / 保存成功）。
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    /// 受限 / 需要 Pro（触发付费墙）。
    static func warning() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }

    /// 出错（导出失败、保存失败）。
    static func error() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }
}
