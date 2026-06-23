//
//  Color+Lumen.swift
//  LumenPuzzle
//
//  全局配色。优先引用 Assets 中的 Color Set（支持深色模式），
//  并提供安全的兜底常量，确保即使资源缺失也不会崩溃。
//

import SwiftUI

extension Color {

    /// 品牌强调色（暖金光）。对应 Assets 中的 "AccentColor"。
    static let lumenAccent = Color("AccentColor")

    /// 背景渐变顶部色。
    static let lumenBackgroundTop = Color("BackgroundTop")

    /// 背景渐变底部色。
    static let lumenBackgroundBottom = Color("BackgroundBottom")

    /// 主文本色。
    static let lumenText = Color("TextPrimary")

    /// 次要文本色。
    static let lumenTextSecondary = Color("TextSecondary")

    /// 卡片表面色。
    static let lumenSurface = Color("Surface")
}

extension ShapeStyle where Self == LinearGradient {

    /// 全局背景渐变：从深邃夜空到近黑，营造静谧的解谜氛围。
    static var lumenBackground: LinearGradient {
        LinearGradient(
            colors: [.lumenBackgroundTop, .lumenBackgroundBottom],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}
