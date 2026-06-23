//
//  ImageExporter.swift
//  PixelStudio
//
//  本地导出：PNG（单帧）与 GIF（多帧动画）。全部使用 ImageIO，无任何
//  网络依赖。导出时按整数倍最近邻放大，避免像素被插值模糊。
//

import UIKit
import ImageIO
import UniformTypeIdentifiers

enum ExportError: LocalizedError {
    case renderFailed
    case encodeFailed

    var errorDescription: String? {
        switch self {
        case .renderFailed: return NSLocalizedString("export.error.render", comment: "")
        case .encodeFailed: return NSLocalizedString("export.error.encode", comment: "")
        }
    }
}

enum ImageExporter {

    /// 单帧 PNG。`scale` 为整数放大倍数。
    static func pngData(from frame: PixelBuffer, layers: [PixelRenderer.LayerInput], scale: Int) throws -> Data {
        guard let base = PixelRenderer.compositeImage(layers: layers,
                                                      width: frame.width,
                                                      height: frame.height) else {
            throw ExportError.renderFailed
        }
        guard let scaled = PixelRenderer.upscaled(base, scale: max(1, scale)) else {
            throw ExportError.renderFailed
        }
        let mutableData = NSMutableData()
        guard let dest = CGImageDestinationCreateWithData(mutableData as CFMutableData,
                                                          UTType.png.identifier as CFString, 1, nil) else {
            throw ExportError.encodeFailed
        }
        CGImageDestinationAddImage(dest, scaled, nil)
        guard CGImageDestinationFinalize(dest) else { throw ExportError.encodeFailed }
        return mutableData as Data
    }

    /// 多帧 GIF。`frames` 为已合成的逐帧 CGImage，`delays` 为每帧秒数。
    static func gifData(frames: [CGImage], delays: [Double], scale: Int, loopForever: Bool = true) throws -> Data {
        guard !frames.isEmpty else { throw ExportError.renderFailed }

        let mutableData = NSMutableData()
        guard let dest = CGImageDestinationCreateWithData(mutableData as CFMutableData,
                                                          UTType.gif.identifier as CFString,
                                                          frames.count, nil) else {
            throw ExportError.encodeFailed
        }

        let fileProps: [String: Any] = [
            kCGImagePropertyGIFDictionary as String: [
                kCGImagePropertyGIFLoopCount as String: loopForever ? 0 : 1
            ]
        ]
        CGImageDestinationSetProperties(dest, fileProps as CFDictionary)

        for (index, frame) in frames.enumerated() {
            let img = PixelRenderer.upscaled(frame, scale: max(1, scale)) ?? frame
            let delay = index < delays.count ? delays[index] : 0.1
            let frameProps: [String: Any] = [
                kCGImagePropertyGIFDictionary as String: [
                    kCGImagePropertyGIFUnclampedDelayTime as String: delay,
                    kCGImagePropertyGIFDelayTime as String: delay
                ]
            ]
            CGImageDestinationAddImage(dest, img, frameProps as CFDictionary)
        }

        guard CGImageDestinationFinalize(dest) else { throw ExportError.encodeFailed }
        return mutableData as Data
    }

    /// 写入临时目录并返回 URL，便于 ShareLink / UIActivityViewController 分享。
    static func writeTemporary(_ data: Data, fileName: String) throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try data.write(to: url, options: .atomic)
        return url
    }
}
