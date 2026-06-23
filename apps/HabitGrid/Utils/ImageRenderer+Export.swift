//
//  ImageRenderer+Export.swift
//  HabitGrid
//
//  将 SwiftUI 视图渲染为图片，用于“导出热力图截图分享”。
//

import SwiftUI

#if canImport(UIKit)
import UIKit

enum HeatmapExporter {

    /// 将任意 SwiftUI 视图渲染为高清 UIImage（@3x）。
    /// - Parameter view: 待渲染的视图。
    /// - Returns: 渲染后的图片，失败返回 nil。
    @MainActor
    static func render<Content: View>(_ view: Content, scale: CGFloat = 3.0) -> UIImage? {
        let renderer = ImageRenderer(content: view)
        renderer.scale = scale
        renderer.isOpaque = false
        return renderer.uiImage
    }
}

/// 用于 `.sheet` 分享面板的 UIActivityViewController 包装。
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
#endif
