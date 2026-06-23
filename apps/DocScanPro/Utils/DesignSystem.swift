//
//  DesignSystem.swift
//  DocScanPro
//
//  设计系统：集中管理间距、圆角、阴影、动效与触觉反馈令牌。
//  目的——让全 App 的视觉语言保持一致，达到可被 Apple 推荐的品质门槛。
//  颜色仍以 Asset Catalog 的语义色（AccentColor + 系统语义色）为准，
//  以保证浅色/深色模式自动适配。
//

import SwiftUI
import UIKit

enum DS {

    /// 8pt 基准间距系统。所有 padding / spacing 应取自此处，避免散落的魔法数字。
    enum Spacing {
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
    }

    /// 统一圆角半径。卡片/缩略图/弹层各取一档，保持视觉节奏一致。
    enum Radius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
    }

    /// 轻柔阴影令牌。避免过深、生硬的投影。
    struct Shadow {
        let color: Color
        let radius: CGFloat
        let y: CGFloat

        /// 卡片浮起阴影：柔和、近似环境光。
        static let card = Shadow(color: .black.opacity(0.08), radius: 8, y: 3)
        /// 强调元素（如悬浮按钮）的彩色光晕。
        static func accent(_ tint: Color) -> Shadow {
            Shadow(color: tint.opacity(0.35), radius: 12, y: 5)
        }
    }

    /// 统一动效曲线。
    enum Motion {
        /// 通用弹簧动画：用于状态切换、收藏、出现/消失。
        static let spring = Animation.spring(response: 0.38, dampingFraction: 0.8)
        /// 更轻快的微交互。
        static let snappy = Animation.spring(response: 0.28, dampingFraction: 0.78)
    }
}

// MARK: - 阴影修饰便捷扩展

extension View {
    /// 应用设计系统阴影令牌。
    func dsShadow(_ shadow: DS.Shadow) -> some View {
        self.shadow(color: shadow.color, radius: shadow.radius, x: 0, y: shadow.y)
    }
}

// MARK: - 触觉反馈

/// 全局触觉反馈封装。所有关键交互都应给出与系统一致的触感，
/// 这是「精致 App」体感的重要来源。生成器复用以降低延迟。
@MainActor
enum Haptics {
    private static let notification = UINotificationFeedbackGenerator()
    private static let selection = UISelectionFeedbackGenerator()
    private static let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private static let mediumImpact = UIImpactFeedbackGenerator(style: .medium)

    /// 操作成功（扫描完成、购买成功、OCR 完成）。
    static func success() {
        notification.notificationOccurred(.success)
    }

    /// 操作失败 / 错误。
    static func error() {
        notification.notificationOccurred(.error)
    }

    /// 选择变化（切换收藏、切换标签、选颜色）。
    static func selectionChanged() {
        selection.selectionChanged()
    }

    /// 轻触反馈（复制、轻量按钮）。
    static func tapLight() {
        lightImpact.impactOccurred()
    }

    /// 中等冲击（发起扫描等主操作）。
    static func tapMedium() {
        mediumImpact.impactOccurred()
    }
}
