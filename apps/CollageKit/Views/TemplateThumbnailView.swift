//
//  TemplateThumbnailView.swift
//  CollageKit
//
//  模板缩略图：用色块画出插槽排版，用于模板选择与预览。
//

import SwiftUI

struct TemplateThumbnailView: View {
    let template: CollageTemplate
    var spacing: CGFloat = 3
    var cornerRadius: CGFloat = 4
    /// 渐变填充让缩略图更精致。
    var palette: [Color] = [
        Color(hex: "#FDE4CF"), Color(hex: "#C8B6FF"),
        Color(hex: "#BDE0FE"), Color(hex: "#A0E8AF"),
        Color(hex: "#FFC2D1"), Color(hex: "#FFE5A0")
    ]

    var body: some View {
        GeometryReader { geo in
            let size = aspectFitSize(in: geo.size, ratio: template.preferredRatio.ratio)
            ZStack {
                ForEach(template.slots) { slot in
                    let frame = CollageLayout.frame(for: slot,
                                                    canvasSize: size,
                                                    border: 0,
                                                    spacing: spacing)
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(palette[slot.id % palette.count].gradient)
                        .frame(width: frame.width, height: frame.height)
                        .position(x: frame.midX, y: frame.midY)
                }
            }
            .frame(width: size.width, height: size.height)
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .accessibilityHidden(true)
    }

    private func aspectFitSize(in container: CGSize, ratio: CGFloat) -> CGSize {
        if ratio >= 1 {
            let w = min(container.width, container.height * ratio)
            return CGSize(width: w, height: w / ratio)
        } else {
            let h = min(container.height, container.width / ratio)
            return CGSize(width: h * ratio, height: h)
        }
    }
}

#Preview {
    LazyVGrid(columns: [GridItem(), GridItem()], spacing: 16) {
        ForEach(TemplateLibrary.all.prefix(6)) { tpl in
            TemplateThumbnailView(template: tpl)
                .frame(height: 120)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    .padding()
}
