//
//  PixelFrame.swift
//  PixelStudio
//
//  动画的一帧。包含若干图层与该帧的播放时长。
//

import Foundation
import SwiftData

@Model
final class PixelFrame {
    /// 时间轴顺序。
    var order: Int
    /// 该帧停留时长（秒），用于动画预览与 GIF 导出。
    var duration: Double

    @Relationship(deleteRule: .cascade, inverse: \PixelLayer.frame)
    var layers: [PixelLayer]

    var project: PixelProject?

    init(order: Int, duration: Double = 0.12, layers: [PixelLayer] = []) {
        self.order = order
        self.duration = duration
        self.layers = layers
    }

    /// 按 order 升序的图层。
    var sortedLayers: [PixelLayer] {
        layers.sorted { $0.order < $1.order }
    }
}
