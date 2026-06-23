//
//  DesignSystem.swift
//  IronLog
//
//  设计令牌的唯一来源：强调色、间距网格、圆角、阴影。
//  所有页面统一引用这里，保证「被 Apple 推荐」级别的视觉一致性。
//

import SwiftUI

extension Color {
    /// 主题强调色（来自 Assets.xcassets/AccentColor，浅/深色各一套）。
    static let ironAccent = Color("AccentColor")
}

/// 间距 / 圆角 / 阴影等设计常量，遵循 4 / 8 / 16 网格。
enum Theme {
    // MARK: 间距网格（4 的倍数）
    enum Space {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
    }

    // MARK: 圆角
    static let cardCorner: CGFloat = 16
    static let chipCorner: CGFloat = 10
    static let buttonCorner: CGFloat = 14
    static let heroCorner: CGFloat = 20

    // MARK: 兼容旧引用（cardStyle 使用）
    static let spacing: CGFloat = Space.md
    static let cardPadding: CGFloat = Space.lg

    // MARK: 阴影（轻柔自然，不刺眼）
    enum Shadow {
        /// 卡片：贴近表面的浅阴影，提供层次而不抢眼。
        static let cardColor = Color.black.opacity(0.05)
        static let cardRadius: CGFloat = 6
        static let cardY: CGFloat = 2
        /// 悬浮元素（休息条等）：略强的投影以脱离背景。
        static let floatingColor = Color.black.opacity(0.12)
        static let floatingRadius: CGFloat = 10
        static let floatingY: CGFloat = 3
    }
}

extension View {
    /// 标准卡片样式：表面背景 + 连续圆角 + 轻柔阴影，自动适配深色模式。
    func cardStyle() -> some View {
        self
            .padding(Theme.cardPadding)
            .background(
                RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
            .shadow(
                color: Theme.Shadow.cardColor,
                radius: Theme.Shadow.cardRadius,
                y: Theme.Shadow.cardY
            )
    }

    /// 悬浮卡片阴影（休息计时条等脱离背景的元素）。
    func floatingShadow() -> some View {
        shadow(
            color: Theme.Shadow.floatingColor,
            radius: Theme.Shadow.floatingRadius,
            y: Theme.Shadow.floatingY
        )
    }
}
