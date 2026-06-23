//
//  Theme.swift
//  PaperGames
//
//  全局视觉主题：颜色扩展与设计令牌（spacing / radius / shadow）。
//  颜色优先引用 Assets 中的 ColorSet，保证深色模式自动适配。
//

import SwiftUI

extension Color {
    /// 主强调色（来自 AccentColor / AppAccent）。
    static let appAccent = Color("AppAccent")
    /// 次强调色。
    static let appSecondary = Color("AppSecondary")
    /// 主背景。
    static let appBackground = Color("AppBackground")
    /// 卡片/面板背景。
    static let appSurface = Color("AppSurface")
}

/// 8pt 网格间距系统：统一所有 padding / spacing，避免散落的魔法数字。
enum AppSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
}

/// 统一圆角半径层级。
enum AppRadius {
    static let small: CGFloat = 10
    static let medium: CGFloat = 16
    static let large: CGFloat = 20
    static let xlarge: CGFloat = 24
}

/// 纸张质感的间距/圆角等设计常量（保持向后兼容）。
enum AppMetrics {
    static let cornerRadius: CGFloat = AppRadius.medium
    static let cardPadding: CGFloat = AppSpacing.lg
    static let gridSpacing: CGFloat = 1
}

// MARK: - 卡片样式

/// 统一的卡片表面样式：表面色 + 连续圆角 + 轻柔阴影 + 极细描边。
/// 集中管理保证全局视觉一致（圆角/阴影不再各处手写）。
struct CardSurface: ViewModifier {
    var cornerRadius: CGFloat = AppRadius.medium
    var fill: Color = .appSurface

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(fill)
                    .shadow(color: .black.opacity(0.05), radius: 10, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.04), lineWidth: 0.5)
            )
    }
}

extension View {
    /// 应用统一的卡片表面（圆角 + 轻柔阴影 + 描边）。
    func cardSurface(cornerRadius: CGFloat = AppRadius.medium, fill: Color = .appSurface) -> some View {
        modifier(CardSurface(cornerRadius: cornerRadius, fill: fill))
    }
}

// MARK: - 按钮样式

/// 轻微缩放的按压反馈样式：替代 `.plain`，为自定义卡片/按钮提供统一的触感。
struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PressableButtonStyle {
    /// 统一的可按压卡片样式。
    static var pressable: PressableButtonStyle { PressableButtonStyle() }
}
