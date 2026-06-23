//
//  Color+Theme.swift
//  CleanAlbum
//
//  主题色与设计令牌。颜色优先取自 Asset Catalog（支持深色模式）。
//

import SwiftUI
import UIKit

extension Color {
    /// 品牌强调色（定义于 Assets.xcassets/AccentColor）。
    static let brand = Color.accentColor

    /// 卡片背景（随浅/深色自适应）。
    static var cardBackground: Color {
        Color(uiColor: .secondarySystemBackground)
    }

    /// 主背景。
    static var appBackground: Color {
        Color(uiColor: .systemBackground)
    }

    /// 危险/删除操作的语义色。集中定义以便统一调校与对比度审计。
    static let destructive = Color.red

    /// "可释放/积极成果"语义色。
    static let positive = Color.green
}

/// 间距 / 圆角 / 阴影等设计令牌，统一视觉节奏（8pt 网格）。
enum Layout {
    // 间距阶梯（4 / 8 / 12 / 16 / 24 / 32）。
    static let spacingXS: CGFloat = 4
    static let spacingSM: CGFloat = 8
    static let spacingMD: CGFloat = 12
    static let spacing: CGFloat = 16
    static let spacingLG: CGFloat = 24
    static let spacingXL: CGFloat = 32

    // 圆角阶梯。
    static let cornerRadiusSM: CGFloat = 8
    static let cornerRadiusMD: CGFloat = 12
    static let cornerRadius: CGFloat = 16

    static let cardPadding: CGFloat = 16

    /// 图标芯片（卡片左侧的彩色圆角图标容器）边长。
    static let iconChip: CGFloat = 52
}

/// 统一的卡片表面样式：圆角 + 自适应背景 + 轻柔阴影。
///
/// 抽出 ViewModifier，消除各视图里重复的 `padding/background/clipShape`，
/// 保证圆角、内边距、阴影在全 App 一致（Apple 推荐品质的关键基础）。
struct CardSurface: ViewModifier {
    var padding: CGFloat = Layout.cardPadding
    var cornerRadius: CGFloat = Layout.cornerRadius

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            // 阴影极轻，仅用于把卡片从背景中托起，不喧宾夺主。
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

extension View {
    /// 应用统一卡片表面样式。
    func cardSurface(padding: CGFloat = Layout.cardPadding,
                     cornerRadius: CGFloat = Layout.cornerRadius) -> some View {
        modifier(CardSurface(padding: padding, cornerRadius: cornerRadius))
    }
}
