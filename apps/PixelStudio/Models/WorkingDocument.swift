//
//  WorkingDocument.swift
//  PixelStudio
//
//  编辑期的内存文档。使用值类型 + 写时复制（COW）使得撤销快照非常廉价：
//  拍快照只是保留数组引用，真正改动某图层时才发生一次字节拷贝。
//

import Foundation

struct WorkingLayer: Identifiable, Equatable {
    let id: UUID
    var name: String
    var isVisible: Bool
    var opacity: Double
    var buffer: PixelBuffer

    init(id: UUID = UUID(),
         name: String,
         isVisible: Bool = true,
         opacity: Double = 1,
         buffer: PixelBuffer) {
        self.id = id
        self.name = name
        self.isVisible = isVisible
        self.opacity = opacity
        self.buffer = buffer
    }
}

struct WorkingFrame: Identifiable, Equatable {
    let id: UUID
    var duration: Double
    /// 索引 0 为最底层。
    var layers: [WorkingLayer]

    init(id: UUID = UUID(), duration: Double = 0.12, layers: [WorkingLayer]) {
        self.id = id
        self.duration = duration
        self.layers = layers
    }
}
