//
//  Color+Hex.swift
//  CollageKit
//
//  Color <-> Hex 字符串互转工具，用于把 SwiftUI Color 持久化到 SwiftData。
//

import SwiftUI
import UIKit

extension Color {
    /// 通过十六进制字符串创建颜色，支持 "#RRGGBB" / "RRGGBB" / "#RRGGBBAA"。
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)

        let r, g, b, a: Double
        switch cleaned.count {
        case 6:
            r = Double((value & 0xFF0000) >> 16) / 255
            g = Double((value & 0x00FF00) >> 8) / 255
            b = Double(value & 0x0000FF) / 255
            a = 1.0
        case 8:
            r = Double((value & 0xFF000000) >> 24) / 255
            g = Double((value & 0x00FF0000) >> 16) / 255
            b = Double((value & 0x0000FF00) >> 8) / 255
            a = Double(value & 0x000000FF) / 255
        default:
            r = 1; g = 1; b = 1; a = 1
        }
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }

    /// 转为 "#RRGGBB" 字符串。
    /// 系统取色器可能返回 Display P3 / 灰度等非 sRGB 颜色，统一换算到 sRGB 并夹取到 0~1，
    /// 避免分量越界导致持久化的 Hex 失真。
    var hexString: String {
        let ui = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        if !ui.getRed(&r, green: &g, blue: &b, alpha: &a),
           let srgb = CGColorSpace(name: CGColorSpace.sRGB),
           let converted = ui.cgColor.converted(to: srgb, intent: .defaultIntent, options: nil),
           let comps = converted.components, comps.count >= 3 {
            r = comps[0]; g = comps[1]; b = comps[2]
        }
        let clamp = { (v: CGFloat) in min(max(v, 0), 1) }
        return String(format: "#%02X%02X%02X",
                      Int(round(clamp(r) * 255)),
                      Int(round(clamp(g) * 255)),
                      Int(round(clamp(b) * 255)))
    }
}

extension UIColor {
    convenience init(hex: String) {
        self.init(Color(hex: hex))
    }
}
