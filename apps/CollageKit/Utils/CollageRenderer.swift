//
//  CollageRenderer.swift
//  CollageKit
//
//  Core Graphics 本地合成引擎：把工程渲染为一张高分辨率 UIImage 用于导出。
//  渲染流程：背景 → 各插槽照片（aspect-fill 裁切 + 用户平移缩放 + 圆角）→ 文字 → 水印。
//

import UIKit

struct CollageRenderer {

    /// 导出长边像素。社交平台 2048 足够清晰。
    var exportMaxDimension: CGFloat = 2048
    /// 是否绘制水印（未购买 Pro 时为 true）。
    var addWatermark: Bool = true

    /// 渲染工程为图片。
    /// - Parameter loadedImages: 预先解码好的图片，键为插槽序号。
    func render(project: CollageProject,
                loadedImages: [Int: UIImage]) -> UIImage {
        let canvasSize = project.aspectRatio.canvasSize(maxDimension: exportMaxDimension)
        let factor = CollageLayout.scale(forCanvas: canvasSize)
        let border = CGFloat(project.borderWidth) * factor
        let spacing = CGFloat(project.spacing) * factor
        let corner = CGFloat(project.cornerRadius) * factor

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: canvasSize, format: format)

        return renderer.image { ctx in
            let cg = ctx.cgContext

            drawBackground(project: project, size: canvasSize, in: cg)

            for slot in project.template.slots {
                let frame = CollageLayout.frame(for: slot,
                                                canvasSize: canvasSize,
                                                border: border,
                                                spacing: spacing)
                guard frame.width > 1, frame.height > 1 else { continue }

                let photo = project.photo(forSlot: slot.id)
                let image = photo.flatMap { loadedImages[$0.slotIndex] }
                drawSlot(image: image,
                         photo: photo,
                         frame: frame,
                         corner: corner,
                         in: cg)
            }

            drawTexts(project: project, size: canvasSize, in: cg)

            if addWatermark {
                drawWatermark(size: canvasSize, in: cg)
            }
        }
    }

    // MARK: - 背景

    private func drawBackground(project: CollageProject,
                                size: CGSize,
                                in cg: CGContext) {
        let rect = CGRect(origin: .zero, size: size)
        switch project.backgroundKind {
        case .solid:
            cg.setFillColor(UIColor(hex: project.backgroundColorHex).cgColor)
            cg.fill(rect)
        case .gradient:
            cg.saveGState()
            let colors = [UIColor(hex: project.gradientStartHex).cgColor,
                          UIColor(hex: project.gradientEndHex).cgColor] as CFArray
            let space = CGColorSpaceCreateDeviceRGB()
            guard let gradient = CGGradient(colorsSpace: space,
                                            colors: colors,
                                            locations: [0, 1]) else {
                cg.restoreGState(); return
            }
            let angle = CGFloat(project.gradientAngle) * .pi / 180
            let dx = cos(angle), dy = sin(angle)
            let start = CGPoint(x: size.width / 2 - dx * size.width / 2,
                                y: size.height / 2 - dy * size.height / 2)
            let end = CGPoint(x: size.width / 2 + dx * size.width / 2,
                              y: size.height / 2 + dy * size.height / 2)
            cg.drawLinearGradient(gradient, start: start, end: end, options: [])
            cg.restoreGState()
        }
    }

    // MARK: - 插槽

    private func drawSlot(image: UIImage?,
                          photo: CollagePhoto?,
                          frame: CGRect,
                          corner: CGFloat,
                          in cg: CGContext) {
        cg.saveGState()
        let path = UIBezierPath(roundedRect: frame, cornerRadius: corner)
        cg.addPath(path.cgPath)
        cg.clip()

        if let image {
            let drawRect = aspectFillRect(imageSize: image.size,
                                          in: frame,
                                          photo: photo)
            image.draw(in: drawRect)
        } else {
            // 空插槽：浅灰占位
            cg.setFillColor(UIColor(white: 0.92, alpha: 1).cgColor)
            cg.fill(frame)
        }
        cg.restoreGState()
    }

    /// 计算 aspect-fill 绘制矩形，并叠加用户的缩放与归一化偏移。
    private func aspectFillRect(imageSize: CGSize,
                               in frame: CGRect,
                               photo: CollagePhoto?) -> CGRect {
        let scaleToFill = max(frame.width / imageSize.width,
                              frame.height / imageSize.height)
        let userScale = CGFloat(photo?.scale ?? 1)
        let finalScale = scaleToFill * userScale

        let drawW = imageSize.width * finalScale
        let drawH = imageSize.height * finalScale

        // 居中后再按归一化偏移移动（偏移以插槽尺寸为基准）
        let offsetX = CGFloat(photo?.offsetX ?? 0) * frame.width
        let offsetY = CGFloat(photo?.offsetY ?? 0) * frame.height

        return CGRect(x: frame.midX - drawW / 2 + offsetX,
                      y: frame.midY - drawH / 2 + offsetY,
                      width: drawW,
                      height: drawH)
    }

    // MARK: - 文字

    private func drawTexts(project: CollageProject,
                           size: CGSize,
                           in cg: CGContext) {
        for text in project.texts where !text.content.isEmpty {
            let pointSize = CGFloat(text.fontSize) / 1000 * size.height
            let font = UIFont.systemFont(ofSize: pointSize, weight: text.weight.uiFontWeight)
            let paragraph = NSMutableParagraphStyle()
            paragraph.alignment = .center
            let attrs: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: UIColor(hex: text.colorHex),
                .paragraphStyle: paragraph
            ]
            let attr = NSAttributedString(string: text.content, attributes: attrs)
            let textSize = attr.size()

            let center = CGPoint(x: CGFloat(text.normX) * size.width,
                                 y: CGFloat(text.normY) * size.height)

            cg.saveGState()
            cg.translateBy(x: center.x, y: center.y)
            cg.rotate(by: CGFloat(text.rotation) * .pi / 180)
            let drawRect = CGRect(x: -textSize.width / 2,
                                  y: -textSize.height / 2,
                                  width: textSize.width,
                                  height: textSize.height)
            attr.draw(in: drawRect)
            cg.restoreGState()
        }
    }

    // MARK: - 水印

    private func drawWatermark(size: CGSize, in cg: CGContext) {
        let text = "CollageKit"
        let pointSize = size.height * 0.028
        let font = UIFont.systemFont(ofSize: pointSize, weight: .semibold)
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.white.withAlphaComponent(0.85)
        ]
        let attr = NSAttributedString(string: text, attributes: attrs)
        let textSize = attr.size()
        let padding = size.height * 0.02
        let origin = CGPoint(x: size.width - textSize.width - padding,
                             y: size.height - textSize.height - padding)

        // 半透明胶囊底，保证浅色背景上也可见
        let bgRect = CGRect(x: origin.x - padding * 0.6,
                            y: origin.y - padding * 0.3,
                            width: textSize.width + padding * 1.2,
                            height: textSize.height + padding * 0.6)
        cg.setFillColor(UIColor.black.withAlphaComponent(0.28).cgColor)
        let bgPath = UIBezierPath(roundedRect: bgRect, cornerRadius: bgRect.height / 2)
        cg.addPath(bgPath.cgPath)
        cg.fillPath()

        attr.draw(at: origin)
    }

}
