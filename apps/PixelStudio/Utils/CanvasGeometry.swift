//
//  CanvasGeometry.swift
//  PixelStudio
//
//  屏幕坐标 <-> 像素坐标的换算。画布始终等比居中、整像素对齐，
//  保证一个画布像素在屏幕上是正方形且边缘清晰。
//

import CoreGraphics

struct CanvasGeometry {
    let viewSize: CGSize
    let pixelWidth: Int
    let pixelHeight: Int

    /// 每个画布像素在屏幕上的边长（point）。
    var pixelSize: CGFloat {
        guard pixelWidth > 0, pixelHeight > 0 else { return 1 }
        let fit = min(viewSize.width / CGFloat(pixelWidth),
                      viewSize.height / CGFloat(pixelHeight))
        return max(fit, 0.0001)
    }

    /// 画布在屏幕上的实际绘制区域（居中）。
    var imageRect: CGRect {
        let w = pixelSize * CGFloat(pixelWidth)
        let h = pixelSize * CGFloat(pixelHeight)
        return CGRect(x: (viewSize.width - w) / 2,
                      y: (viewSize.height - h) / 2,
                      width: w, height: h)
    }

    /// 把屏幕坐标转换为画布像素坐标（可超出边界，绘制原语会自行裁剪）。
    func pixel(at point: CGPoint) -> (x: Int, y: Int) {
        let rect = imageRect
        let x = Int(floor((point.x - rect.minX) / pixelSize))
        let y = Int(floor((point.y - rect.minY) / pixelSize))
        return (x, y)
    }
}
