//
//  DesignSystem.swift
//  CalmBox
//
//  设计令牌的唯一来源：间距、圆角、阴影、品牌配色与各场景主题色。
//  全 App 统一从 Theme 取值，避免十六进制色值与魔法数字散落各处。
//

import SwiftUI

enum Theme {

    // MARK: - 间距（8pt 栅格）

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
    }

    // MARK: - 圆角

    enum Radius {
        static let small: CGFloat = 14
        static let medium: CGFloat = 18
        static let large: CGFloat = 24
    }

    // MARK: - 品牌配色

    enum Palette {
        /// 品牌主色（薰衣草紫 → 暮蓝），用于付费墙、解锁入口与冥想场景。
        static let brandStart = Color(hex: "#614385")
        static let brandEnd   = Color(hex: "#516395")
        /// 主页背景收尾的淡紫色调。
        static let surfaceTint = Color(hex: "#E8EAF6")

        /// 品牌主渐变（左上 → 右下）。
        static var brandGradient: [Color] { [brandStart, brandEnd] }
    }

    // MARK: - 场景主题色

    /// 每个解压场景的配色：accent 为主色，gradient 为卡片/背景渐变。
    enum Scene {
        static func gradient(_ kind: SceneKind) -> [Color] {
            switch kind {
            case .bubbleWrap: return [Color(hex: "#7F7FD5"), Color(hex: "#86A8E7")]
            case .spinner:    return [Color(hex: "#FF9A9E"), Color(hex: "#FAD0C4")]
            case .whiteNoise: return [Color(hex: "#43C6AC"), Color(hex: "#191654")]
            case .breathing:  return [Color(hex: "#5B86E5"), Color(hex: "#36D1DC")]
            case .meditation: return Palette.brandGradient
            }
        }

        /// 场景主色（取渐变首色），用于强调元素、进度条、图标着色。
        static func accent(_ kind: SceneKind) -> Color {
            gradient(kind).first ?? .accentColor
        }
    }

    // MARK: - 阴影

    enum Shadow {
        /// 轻柔的卡片阴影，随主题色着色而非纯黑，更自然。
        static func card(_ tint: Color) -> (color: Color, radius: CGFloat, y: CGFloat) {
            (tint.opacity(0.3), 8, 4)
        }
    }
}

// MARK: - 复用视图修饰

extension View {

    /// 为场景详情页铺设与主题色一致的淡色背景渐变。
    func sceneBackground(_ kind: SceneKind, opacity: Double = 0.15) -> some View {
        background(
            LinearGradient(
                colors: Theme.Scene.gradient(kind).map { $0.opacity(opacity) },
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
    }

    /// 统一的卡片柔和阴影。
    func cardShadow(_ tint: Color) -> some View {
        let s = Theme.Shadow.card(tint)
        return shadow(color: s.color, radius: s.radius, y: s.y)
    }
}
