//
//  PixelLayer.swift
//  PixelStudio
//
//  SwiftData 持久化的图层。像素数据以 RGBA8 原始字节存放在 `pixelData`，
//  编辑时再解码成 PixelBuffer 进行高频运算。
//

import Foundation
import SwiftData

@Model
final class PixelLayer {
    /// 同帧内的叠放顺序，数值越大越靠上层。
    var order: Int
    var name: String
    var isVisible: Bool
    /// 图层整体不透明度，0...1。
    var opacity: Double
    /// RGBA8 原始像素，长度 = width * height * 4。
    @Attribute(.externalStorage) var pixelData: Data

    /// 所属帧（反向关系）。
    var frame: PixelFrame?

    init(order: Int,
         name: String,
         isVisible: Bool = true,
         opacity: Double = 1,
         pixelData: Data) {
        self.order = order
        self.name = name
        self.isVisible = isVisible
        self.opacity = opacity
        self.pixelData = pixelData
    }

    /// 解码为可编辑缓冲。
    func buffer(width: Int, height: Int) -> PixelBuffer {
        PixelBuffer(width: width, height: height, bytes: [UInt8](pixelData))
    }
}
