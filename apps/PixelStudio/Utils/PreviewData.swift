//
//  PreviewData.swift
//  PixelStudio
//
//  仅供 SwiftUI #Preview 使用：内存 ModelContainer + 一张示例像素画。
//

import SwiftData
import SwiftUI

enum PreviewData {
    /// 内存数据库容器（不落盘）。
    static let container: ModelContainer = {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        // swiftlint:disable:next force_try
        return try! ModelContainer(for: PixelProject.self, configurations: config)
    }()

    /// 生成一张带简单图案的 16×16 示例作品。
    @MainActor
    static func sampleProject(in container: ModelContainer) -> PixelProject {
        let context = container.mainContext
        let size = 16
        let project = PixelProject.makeBlank(name: "Sample", size: size, context: context)

        // 在第一帧第一图层画一个红心轮廓，便于预览。
        var buffer = PixelBuffer(width: size, height: size)
        let red = PixelColor(r: 0xB1, g: 0x3E, b: 0x53)
        let heart: [(Int, Int)] = [
            (4, 4), (5, 3), (6, 3), (7, 4), (8, 4), (9, 3), (10, 3), (11, 4),
            (4, 5), (11, 5), (5, 6), (10, 6), (6, 7), (9, 7), (7, 8), (8, 8)
        ]
        for (x, y) in heart { buffer.setColor(red, x: x, y: y) }

        if let frame = project.sortedFrames.first,
           let layer = frame.sortedLayers.first {
            layer.pixelData = Data(buffer.bytes)
        }
        return project
    }
}
