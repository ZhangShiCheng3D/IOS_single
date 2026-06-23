//
//  ImageUtils.swift
//  CollageKit
//
//  图片处理工具：降采样、Data 互转。
//

import UIKit

enum ImageUtils {

    /// 把图片降采样到最大边长不超过 maxDimension，再编码为 JPEG。
    /// 用于存入 SwiftData，避免持久化原始大图导致体积膨胀。
    static func downsampledJPEGData(from image: UIImage,
                                    maxDimension: CGFloat = 1600,
                                    quality: CGFloat = 0.85) -> Data? {
        let resized = downsample(image, maxDimension: maxDimension)
        return resized.jpegData(compressionQuality: quality)
    }

    /// 等比缩小图片，使最长边不超过 maxDimension。放大不处理。
    static func downsample(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        let longest = max(size.width, size.height)
        guard longest > maxDimension else { return image }

        let scale = maxDimension / longest
        let newSize = CGSize(width: size.width * scale,
                             height: size.height * scale)

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    static func image(from data: Data) -> UIImage? {
        UIImage(data: data)
    }
}
