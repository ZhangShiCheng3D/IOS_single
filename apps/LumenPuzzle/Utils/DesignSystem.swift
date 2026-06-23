//
//  DesignSystem.swift
//  LumenPuzzle
//
//  设计令牌（Design Tokens）。集中管理间距、圆角、阴影与动效，
//  确保全局视觉的一致性与「可被 Apple 推荐」的精致度。
//  颜色令牌见 Color+Lumen.swift。
//

import SwiftUI

/// 间距系统（4pt 基准网格）。
enum Spacing {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 20
    static let xl: CGFloat = 28
    static let xxl: CGFloat = 40
}

/// 动效预设。统一全局过渡手感，避免各处随手写 duration。
enum Motion {
    /// 面板/卡片登场。
    static let panel = Animation.spring(response: 0.5, dampingFraction: 0.7)
    /// 一般状态切换。
    static let state = Animation.easeInOut(duration: 0.25)
    /// 提示卡等轻量切换。
    static let soft = Animation.spring(duration: 0.4)
}

extension View {

    /// 主操作按钮的柔和投影：暖金辉光，轻而不刺眼，营造「光」的质感。
    func lumenAccentShadow() -> some View {
        shadow(color: Color.lumenAccent.opacity(0.35), radius: 14, y: 6)
    }

    /// 卡片/表面的轻柔投影，制造层次而非生硬贴合。
    func lumenCardShadow() -> some View {
        shadow(color: Color.black.opacity(0.25), radius: 12, y: 6)
    }
}
