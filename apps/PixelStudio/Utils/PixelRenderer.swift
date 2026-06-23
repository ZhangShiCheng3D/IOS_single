//
//  PixelRenderer.swift
//  PixelStudio
//
//  把图层缓冲合成为可显示的位图。负责：
//  - 多图层从下到上的 alpha 混合（含图层不透明度）
//  - 生成 CGImage / UIImage（最近邻，保持像素硬边缘）
//  纯函数，无状态，便于在主线程快速调用。
//

import UIKit
import CoreGraphics

enum PixelRenderer {

    /// 单个参与合成的图层。
    struct LayerInput {
        let buffer: PixelBuffer
        let opacity: Double   // 0...1
        let isVisible: Bool
    }

    /// 把若干图层合成为预乘 RGBA 字节（供 CGImage 使用）。
    /// 自下而上叠加，source-over 混合。
    static func compositePremultiplied(layers: [LayerInput], width: Int, height: Int) -> [UInt8] {
        var out = [UInt8](repeating: 0, count: width * height * 4) // 预乘，初始全透明

        for layer in layers where layer.isVisible && layer.opacity > 0 {
            let src = layer.buffer.bytes
            guard src.count == out.count else { continue }
            let layerA = layer.opacity

            var i = 0
            while i < out.count {
                let sa = (Double(src[i + 3]) / 255) * layerA
                if sa > 0 {
                    let sr = Double(src[i]) / 255
                    let sg = Double(src[i + 1]) / 255
                    let sb = Double(src[i + 2]) / 255

                    // 目标已是预乘
                    let dr = Double(out[i]) / 255
                    let dg = Double(out[i + 1]) / 255
                    let db = Double(out[i + 2]) / 255
                    let da = Double(out[i + 3]) / 255

                    let outA = sa + da * (1 - sa)
                    let outR = sr * sa + dr * (1 - sa)
                    let outG = sg * sa + dg * (1 - sa)
                    let outB = sb * sa + db * (1 - sa)

                    out[i] = UInt8((outR * 255).rounded().clampedToByte)
                    out[i + 1] = UInt8((outG * 255).rounded().clampedToByte)
                    out[i + 2] = UInt8((outB * 255).rounded().clampedToByte)
                    out[i + 3] = UInt8((outA * 255).rounded().clampedToByte)
                }
                i += 4
            }
        }
        return out
    }

    /// 由预乘字节生成 CGImage。
    static func cgImage(premultiplied bytes: [UInt8], width: Int, height: Int) -> CGImage? {
        guard width > 0, height > 0, bytes.count == width * height * 4 else { return nil }
        var data = bytes
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)

        guard let provider = CGDataProvider(data: Data(bytes: &data, count: data.count) as CFData) else {
            return nil
        }
        return CGImage(width: width,
                       height: height,
                       bitsPerComponent: 8,
                       bitsPerPixel: 32,
                       bytesPerRow: width * 4,
                       space: colorSpace,
                       bitmapInfo: bitmapInfo,
                       provider: provider,
                       decode: nil,
                       shouldInterpolate: false,
                       intent: .defaultIntent)
    }

    /// 合成图层 -> CGImage（原始像素尺寸）。
    static func compositeImage(layers: [LayerInput], width: Int, height: Int) -> CGImage? {
        let bytes = compositePremultiplied(layers: layers, width: width, height: height)
        return cgImage(premultiplied: bytes, width: width, height: height)
    }

    /// 单层缓冲 -> CGImage（用于洋葱皮、缩略图）。
    static func image(from buffer: PixelBuffer, opacity: Double = 1) -> CGImage? {
        compositeImage(layers: [LayerInput(buffer: buffer, opacity: opacity, isVisible: true)],
                       width: buffer.width, height: buffer.height)
    }

    /// 把原始尺寸的 CGImage 以最近邻放大到指定整数倍，用于导出更大的 PNG。
    static func upscaled(_ image: CGImage, scale: Int) -> CGImage? {
        guard scale > 1 else { return image }
        let w = image.width * scale
        let h = image.height * scale
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let ctx = CGContext(data: nil,
                                  width: w, height: h,
                                  bitsPerComponent: 8,
                                  bytesPerRow: w * 4,
                                  space: colorSpace,
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
            return nil
        }
        ctx.interpolationQuality = .none
        ctx.draw(image, in: CGRect(x: 0, y: 0, width: w, height: h))
        return ctx.makeImage()
    }
}

private extension Double {
    /// 把数值夹到 0...255，防止浮点误差导致溢出。
    var clampedToByte: Double { Swift.max(0, Swift.min(255, self)) }
}
