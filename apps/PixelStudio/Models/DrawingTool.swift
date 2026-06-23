//
//  DrawingTool.swift
//  PixelStudio
//
//  编辑器使用的工具与镜像枚举。集中定义，方便工具栏和 ViewModel 共享。
//

import SwiftUI

/// 绘制工具。
enum DrawingTool: String, CaseIterable, Identifiable {
    case pencil
    case eraser
    case fill
    case line
    case rectangle
    case eyedropper

    var id: String { rawValue }

    var titleKey: LocalizedStringKey {
        switch self {
        case .pencil: return "tool.pencil"
        case .eraser: return "tool.eraser"
        case .fill: return "tool.fill"
        case .line: return "tool.line"
        case .rectangle: return "tool.rectangle"
        case .eyedropper: return "tool.eyedropper"
        }
    }

    var systemImage: String {
        switch self {
        case .pencil: return "pencil.tip"
        case .eraser: return "eraser"
        case .fill: return "drop.fill"
        case .line: return "line.diagonal"
        case .rectangle: return "rectangle"
        case .eyedropper: return "eyedropper"
        }
    }

    /// 形状类工具需要起点/终点预览，逐点工具则边拖边画。
    var isShapeTool: Bool {
        self == .line || self == .rectangle
    }
}

/// 镜像绘制轴。可同时开启水平与垂直。
struct MirrorMode: OptionSet {
    let rawValue: Int
    static let horizontal = MirrorMode(rawValue: 1 << 0)
    static let vertical = MirrorMode(rawValue: 1 << 1)
}

/// 画布预设尺寸（正方形）。免费档限制在 32 以内。
enum CanvasSize: Int, CaseIterable, Identifiable {
    case s8 = 8
    case s16 = 16
    case s32 = 32
    case s64 = 64
    case s128 = 128
    case s256 = 256

    var id: Int { rawValue }
    var label: String { "\(rawValue)×\(rawValue)" }

    /// 是否需要 Pro 解锁（> 32 为高级尺寸）。
    var requiresPro: Bool { rawValue > 32 }
}
