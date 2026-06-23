//
//  DesignSystem.swift
//  FastFlow
//
//  设计令牌集中管理：间距、圆角、阴影、动效与卡片样式。
//  目标是让全 App 的视觉语言保持一致（8pt 网格、统一圆角与轻柔阴影），
//  避免散落各处的魔法数字，便于整体调校到「可被推荐」的品质。
//

import SwiftUI

enum DS {
    /// 间距系统（4 / 8 / 16 / 24 / 32 网格）。
    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
    }

    /// 圆角半径层级（小元素 → 卡片 → 大容器）。
    enum Radius {
        static let sm: CGFloat = 10
        static let md: CGFloat = 14
        static let lg: CGFloat = 18
        static let xl: CGFloat = 24
    }

    /// 轻柔阴影，营造层次而不刺眼。
    enum Shadow {
        static let color = Color.black.opacity(0.06)
        static let radius: CGFloat = 12
        static let yOffset: CGFloat = 4
    }

    /// 统一动效曲线。
    enum Motion {
        /// 列表插入/删除、状态切换的默认弹簧。
        static let spring = Animation.spring(response: 0.4, dampingFraction: 0.8)
        /// 进度环等连续值变化。
        static let smooth = Animation.smooth(duration: 0.6)
    }
}

extension View {
    /// 统一卡片样式：材质背景 + 连续圆角 + 轻柔阴影。
    func cardStyle(cornerRadius: CGFloat = DS.Radius.md) -> some View {
        background(
            .regularMaterial,
            in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        )
        .shadow(color: DS.Shadow.color, radius: DS.Shadow.radius, x: 0, y: DS.Shadow.yOffset)
    }
}
