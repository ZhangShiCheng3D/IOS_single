//
//  PixelProject.swift
//  PixelStudio
//
//  一个像素画作品的根模型。持有画布尺寸、调色板、动画帧。
//

import Foundation
import SwiftData

@Model
final class PixelProject {
    @Attribute(.unique) var id: UUID
    var name: String
    var width: Int
    var height: Int
    var createdAt: Date
    var updatedAt: Date
    /// 调色板，存为 hex 字符串数组，便于持久化与展示。
    var paletteHex: [String]

    @Relationship(deleteRule: .cascade, inverse: \PixelFrame.project)
    var frames: [PixelFrame]

    init(name: String,
         width: Int,
         height: Int,
         paletteHex: [String],
         frames: [PixelFrame] = []) {
        self.id = UUID()
        self.name = name
        self.width = width
        self.height = height
        self.createdAt = Date()
        self.updatedAt = Date()
        self.paletteHex = paletteHex
        self.frames = frames
    }

    /// 按 order 升序的帧。
    var sortedFrames: [PixelFrame] {
        frames.sorted { $0.order < $1.order }
    }

    // MARK: - 工厂

    /// 创建一张带单帧、单图层、默认调色板的空白作品。
    static func makeBlank(name: String, size: Int, context: ModelContext) -> PixelProject {
        let project = PixelProject(name: name,
                                   width: size,
                                   height: size,
                                   paletteHex: DefaultPalette.lospec16)
        let emptyLayerData = Data(count: size * size * 4)
        let layer = PixelLayer(order: 0,
                               name: NSLocalizedString("layer.default", comment: ""),
                               pixelData: emptyLayerData)
        let frame = PixelFrame(order: 0, layers: [layer])
        project.frames = [frame]
        context.insert(project)
        return project
    }
}

/// 内置默认调色板。
enum DefaultPalette {
    /// 经典 16 色像素画板（参考 Lospec 风格）。
    static let lospec16: [String] = [
        "#1A1C2C", "#5D275D", "#B13E53", "#EF7D57",
        "#FFCD75", "#A7F070", "#38B764", "#257179",
        "#29366F", "#3B5DC9", "#41A6F6", "#73EFF7",
        "#F4F4F4", "#94B0C2", "#566C86", "#333C57"
    ]
}
