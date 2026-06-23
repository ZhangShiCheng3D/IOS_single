//
//  PixelColor.swift
//  PixelStudio
//
//  轻量的 RGBA8 颜色值类型。像素画需要逐像素读写颜色，使用 4 个 UInt8
//  比 SwiftUI.Color 更适合做高频的画布运算与序列化。
//

import SwiftUI
import UIKit

/// 8-bit 直通（非预乘）RGBA 颜色。
struct PixelColor: Equatable, Hashable, Codable, Identifiable {
    var r: UInt8
    var g: UInt8
    var b: UInt8
    var a: UInt8

    /// 用 hex 字符串作为稳定标识，便于在 SwiftUI List/ForEach 中使用。
    var id: String { hexString }

    init(r: UInt8, g: UInt8, b: UInt8, a: UInt8 = 255) {
        self.r = r
        self.g = g
        self.b = b
        self.a = a
    }

    /// 完全透明像素。
    static let clear = PixelColor(r: 0, g: 0, b: 0, a: 0)
    static let black = PixelColor(r: 0, g: 0, b: 0)
    static let white = PixelColor(r: 255, g: 255, b: 255)

    var isTransparent: Bool { a == 0 }

    // MARK: - Hex 互转

    /// 解析 "#RRGGBB" / "RRGGBB" / "#RRGGBBAA"。失败返回 nil。
    init?(hex: String) {
        let cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
        var value: UInt64 = 0
        guard Scanner(string: cleaned).scanHexInt64(&value) else { return nil }

        switch cleaned.count {
        case 6:
            r = UInt8((value & 0xFF0000) >> 16)
            g = UInt8((value & 0x00FF00) >> 8)
            b = UInt8(value & 0x0000FF)
            a = 255
        case 8:
            r = UInt8((value & 0xFF000000) >> 24)
            g = UInt8((value & 0x00FF0000) >> 16)
            b = UInt8((value & 0x0000FF00) >> 8)
            a = UInt8(value & 0x000000FF)
        default:
            return nil
        }
    }

    /// 不透明时输出 "#RRGGBB"，带透明度时输出 "#RRGGBBAA"。
    var hexString: String {
        if a == 255 {
            return String(format: "#%02X%02X%02X", r, g, b)
        }
        return String(format: "#%02X%02X%02X%02X", r, g, b, a)
    }

    // MARK: - SwiftUI / UIKit 互转

    var color: Color {
        Color(.sRGB,
              red: Double(r) / 255,
              green: Double(g) / 255,
              blue: Double(b) / 255,
              opacity: Double(a) / 255)
    }

    init(_ color: Color) {
        let ui = UIColor(color)
        var rr: CGFloat = 0, gg: CGFloat = 0, bb: CGFloat = 0, aa: CGFloat = 0
        ui.getRed(&rr, green: &gg, blue: &bb, alpha: &aa)
        // ColorPicker 可能返回 Display P3 的广色域分量（<0 或 >1）。直接 *255 转
        // UInt8 会触发溢出陷阱崩溃，故先夹到 0...1。
        @inline(__always) func byte(_ v: CGFloat) -> UInt8 {
            UInt8((Swift.max(0, Swift.min(1, v)) * 255).rounded())
        }
        r = byte(rr)
        g = byte(gg)
        b = byte(bb)
        a = byte(aa)
    }

    /// 相对亮度，用于决定棋盘格/选中描边的对比色。
    var luminance: Double {
        (0.299 * Double(r) + 0.587 * Double(g) + 0.114 * Double(b)) / 255
    }
}
