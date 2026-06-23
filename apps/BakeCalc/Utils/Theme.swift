//
//  Theme.swift
//  BakeCalc
//
//  全局视觉风格定义。颜色取自 Assets.xcassets 中的 ColorSet，
//  自动适配深色模式。集中管理便于矩阵内其他产品复用。
//

import SwiftUI

extension Color {
    /// 主题强调色（暖焦糖色，呼应烘焙主题）。对应 AccentColor / BCAccent。
    static let bcAccent = Color("BCAccent")
    /// 次要强调色（柔和奶油），用于渐变与高亮。
    static let bcSecondary = Color("BCSecondary")
    /// 卡片背景色。
    static let bcCard = Color("BCCard")
    /// 页面背景色。
    static let bcBackground = Color("BCBackground")
}

/// 通用尺寸与间距常量，保证全局一致性（8pt 网格）。
enum BCMetrics {
    static let cornerRadius: CGFloat = 16
    static let cardPadding: CGFloat = 16
    static let sectionSpacing: CGFloat = 20
    static let iconSize: CGFloat = 28
}

/// 全局动效令牌：统一弹簧曲线，避免各处手写不一致的过渡。
enum BCMotion {
    /// 标准弹簧：用于交换、切换、增删等交互。
    static let spring: Animation = .spring(response: 0.35, dampingFraction: 0.82)
}

/// 可复用的卡片容器修饰符。
struct BCCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(BCMetrics.cardPadding)
            .background(Color.bcCard)
            .clipShape(RoundedRectangle(cornerRadius: BCMetrics.cornerRadius, style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}

extension View {
    /// 应用标准卡片样式。
    func bcCard() -> some View {
        modifier(BCCardStyle())
    }
}

/// 轻微缩放的按压反馈样式，用于可点击卡片，营造细腻的触感。
struct BCPressableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.92 : 1.0)
            .animation(BCMotion.spring, value: configuration.isPressed)
    }
}
