//
//  ProEntitlements.swift
//  PixelStudio
//
//  集中定义免费档限制与 Pro 解锁的功能点。买断后全部解锁。
//

import SwiftUI

/// 触发付费墙的功能场景。
enum ProFeature: Identifiable {
    case largeCanvas
    case extraLayers
    case animation
    case gifExport

    var id: String {
        switch self {
        case .largeCanvas: return "largeCanvas"
        case .extraLayers: return "extraLayers"
        case .animation: return "animation"
        case .gifExport: return "gifExport"
        }
    }

    var titleKey: LocalizedStringKey {
        switch self {
        case .largeCanvas: return "pro.feature.largeCanvas.title"
        case .extraLayers: return "pro.feature.extraLayers.title"
        case .animation: return "pro.feature.animation.title"
        case .gifExport: return "pro.feature.gifExport.title"
        }
    }

    var detailKey: LocalizedStringKey {
        switch self {
        case .largeCanvas: return "pro.feature.largeCanvas.detail"
        case .extraLayers: return "pro.feature.extraLayers.detail"
        case .animation: return "pro.feature.animation.detail"
        case .gifExport: return "pro.feature.gifExport.detail"
        }
    }
}

/// 免费档的硬性上限。
enum FreeLimits {
    /// 免费最多图层数。
    static let maxLayers = 2
    /// 免费最多帧数（即不开放动画）。
    static let maxFrames = 1
    /// 免费允许的最大画布边长。
    static let maxCanvasSide = 32
}
