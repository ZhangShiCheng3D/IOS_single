//
//  DesignSystem.swift
//  HabitGrid
//
//  设计令牌：统一的动效曲线与卡片景深，集中管理视觉一致性，
//  让全 App 的交互手感与表面层次遵循同一套规则。
//

import SwiftUI

/// 统一的动效曲线，保证全 App 交互手感一致。
enum Motion {
    /// 通用弹簧（打卡、勾选、主题切换）。
    static let spring = Animation.spring(response: 0.3, dampingFraction: 0.7)
    /// 进度/数值的平滑弹簧。
    static let smooth = Animation.spring(response: 0.4, dampingFraction: 0.85)
}

/// 卡片柔和景深。轻到几乎无感，仅在浅色模式下托起表面，避免“刺眼阴影”；
/// 深色模式自动隐藏，遵循 Apple 扁平观感。
private struct CardShadow: ViewModifier {
    @Environment(\.colorScheme) private var scheme

    func body(content: Content) -> some View {
        content.shadow(
            color: .black.opacity(scheme == .dark ? 0.0 : 0.05),
            radius: 8,
            x: 0,
            y: 3
        )
    }
}

extension View {
    /// 为卡片表面添加统一的柔和阴影。
    func cardShadow() -> some View {
        modifier(CardShadow())
    }
}
