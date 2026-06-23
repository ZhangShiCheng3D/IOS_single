//
//  ProjectThumbnail.swift
//  PixelStudio
//
//  从持久化的 PixelProject 生成第一帧的合成缩略图，供作品列表展示。
//  独立于 EditorViewModel，避免为缩略图加载整个编辑器状态。
//

import SwiftUI

enum ProjectThumbnail {
    /// 返回首帧合成后的 CGImage（原始像素尺寸，由调用方放大显示）。
    static func image(for project: PixelProject) -> CGImage? {
        guard let frame = project.sortedFrames.first else { return nil }
        let inputs = frame.sortedLayers.map { layer in
            PixelRenderer.LayerInput(
                buffer: layer.buffer(width: project.width, height: project.height),
                opacity: layer.opacity,
                isVisible: layer.isVisible
            )
        }
        return PixelRenderer.compositeImage(layers: inputs, width: project.width, height: project.height)
    }
}

/// 直接渲染缩略图、带棋盘格底的小组件。
struct ThumbnailView: View {
    let project: PixelProject

    var body: some View {
        GeometryReader { geo in
            ZStack {
                CheckerboardBackground(cell: max(4, geo.size.width / 8))
                if let cg = ProjectThumbnail.image(for: project) {
                    Image(decorative: cg, scale: 1, orientation: .up)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

/// SwiftUI 棋盘格背景，用于表示透明区域。
struct CheckerboardBackground: View {
    var cell: CGFloat = 8

    var body: some View {
        Canvas { ctx, size in
            let cols = Int(ceil(size.width / cell))
            let rows = Int(ceil(size.height / cell))
            for row in 0..<max(1, rows) {
                for col in 0..<max(1, cols) {
                    let isLight = (row + col) % 2 == 0
                    let rect = CGRect(x: CGFloat(col) * cell, y: CGFloat(row) * cell, width: cell, height: cell)
                    ctx.fill(Path(rect),
                             with: .color(isLight ? Color(white: 0.92) : Color(white: 0.82)))
                }
            }
        }
    }
}
