//
//  MiniCollageView.swift
//  CollageKit
//
//  只读的小型拼图预览，用于首页工程卡片。复用 CollageLayout 几何，
//  但不解码大图缓存，直接用存储的（已降采样）图片数据轻量渲染。
//

import SwiftUI

struct MiniCollageView: View {
    let project: CollageProject

    var body: some View {
        GeometryReader { geo in
            let canvas = canvasSize(in: geo.size)
            let factor = CollageLayout.scale(forCanvas: canvas)
            ZStack {
                background.frame(width: canvas.width, height: canvas.height)
                ForEach(project.template.slots) { slot in
                    let frame = CollageLayout.frame(
                        for: slot,
                        canvasSize: canvas,
                        border: CGFloat(project.borderWidth) * factor,
                        spacing: CGFloat(project.spacing) * factor)
                    slotContent(slot)
                        .frame(width: frame.width, height: frame.height)
                        .clipShape(RoundedRectangle(
                            cornerRadius: CGFloat(project.cornerRadius) * factor,
                            style: .continuous))
                        .position(x: frame.midX, y: frame.midY)
                }
            }
            .frame(width: canvas.width, height: canvas.height)
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private func slotContent(_ slot: TemplateSlot) -> some View {
        if let photo = project.photo(forSlot: slot.id),
           let image = UIImage(data: photo.imageData) {
            Image(uiImage: image).resizable().scaledToFill()
        } else {
            Color(.tertiarySystemFill)
        }
    }

    @ViewBuilder
    private var background: some View {
        switch project.backgroundKind {
        case .solid:
            Color(hex: project.backgroundColorHex)
        case .gradient:
            let a = project.gradientAngle * .pi / 180
            LinearGradient(colors: [Color(hex: project.gradientStartHex),
                                    Color(hex: project.gradientEndHex)],
                           startPoint: UnitPoint(x: 0.5 - cos(a) / 2, y: 0.5 - sin(a) / 2),
                           endPoint: UnitPoint(x: 0.5 + cos(a) / 2, y: 0.5 + sin(a) / 2))
        }
    }

    private func canvasSize(in container: CGSize) -> CGSize {
        let ratio = project.aspectRatio.ratio
        if container.width / container.height > ratio {
            return CGSize(width: container.height * ratio, height: container.height)
        } else {
            return CGSize(width: container.width, height: container.width / ratio)
        }
    }
}
