//
//  Theme.swift
//  SeniorHelper
//
//  全局视觉规范：颜色、字号、间距、圆角。
//  银发友好原则——更大的触控区域、更高的对比度、更克制的色彩。
//

import SwiftUI

/// 设计令牌集合。集中管理保证全局视觉一致。
enum Theme {

    // MARK: - 颜色

    /// 主品牌色，跟随 Assets 中的 AccentColor，自动适配深色模式。
    static let accent = Color.accentColor

    /// 危险/紧急色（红色），用于紧急拨号。
    static let danger = Color.red

    /// 成功/确认色（绿色），用于开关、勾选等不承载白色文字的状态指示。
    static let success = Color.green

    /// 拨号/确认型「实心绿按钮」专用色——比系统绿更深，
    /// 保证白色文字在浅色与深色模式下都达到 WCAG AA 对比度。
    static let callAction = Color("CallAction")

    /// 卡片背景色，适配深浅模式。
    static let cardBackground = Color(.secondarySystemBackground)

    /// 页面背景色。
    static let pageBackground = Color(.systemBackground)

    // MARK: - 间距

    /// 标准内边距。银发友好下采用偏大的留白。
    static let padding: CGFloat = 20
    static let smallPadding: CGFloat = 12
    static let largePadding: CGFloat = 28

    // MARK: - 圆角

    static let cornerRadius: CGFloat = 18
    static let smallCornerRadius: CGFloat = 12

    // MARK: - 触控区域

    /// 最小可点击高度，远大于 HIG 的 44pt，便于老年用户操作。
    static let minTapHeight: CGFloat = 60

    /// 大号主操作按钮高度。
    static let primaryButtonHeight: CGFloat = 72
}

// MARK: - 大号主按钮样式

/// 银发友好的主操作按钮：大字号、大触控区、明显的按下反馈。
struct SeniorPrimaryButtonStyle: ButtonStyle {
    var background: Color = Theme.accent
    var foreground: Color = .white

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title2.weight(.bold))
            .frame(maxWidth: .infinity)
            .frame(minHeight: Theme.primaryButtonHeight)
            .background(background)
            .foregroundStyle(foreground)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
            .opacity(configuration.isPressed ? 0.75 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

/// 次级按钮样式：描边、透明背景。
struct SeniorSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title3.weight(.semibold))
            .frame(maxWidth: .infinity)
            .frame(minHeight: Theme.minTapHeight)
            .foregroundStyle(Theme.accent)
            .background(
                RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                    .strokeBorder(Theme.accent, lineWidth: 2)
            )
            .opacity(configuration.isPressed ? 0.6 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == SeniorPrimaryButtonStyle {
    static var seniorPrimary: SeniorPrimaryButtonStyle { .init() }
    static func seniorPrimary(background: Color, foreground: Color = .white) -> SeniorPrimaryButtonStyle {
        .init(background: background, foreground: foreground)
    }
}

extension ButtonStyle where Self == SeniorSecondaryButtonStyle {
    static var seniorSecondary: SeniorSecondaryButtonStyle { .init() }
}
