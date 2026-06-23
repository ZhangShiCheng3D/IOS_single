//
//  Color+Hex.swift
//  HabitGrid
//
//  Color 与 hex 字符串互转。
//

import SwiftUI

extension Color {
    /// 从 hex 字符串创建颜色，支持 "#RGB"、"#RRGGBB"、"#RRGGBBAA"。失败返回 nil。
    init?(hex: String) {
        var sanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        sanitized = sanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        guard Scanner(string: sanitized).scanHexInt64(&rgb) else { return nil }

        let r, g, b, a: Double
        switch sanitized.count {
        case 3: // RGB (12-bit)
            r = Double((rgb >> 8) & 0xF) / 15.0
            g = Double((rgb >> 4) & 0xF) / 15.0
            b = Double(rgb & 0xF) / 15.0
            a = 1.0
        case 6: // RRGGBB
            r = Double((rgb >> 16) & 0xFF) / 255.0
            g = Double((rgb >> 8) & 0xFF) / 255.0
            b = Double(rgb & 0xFF) / 255.0
            a = 1.0
        case 8: // RRGGBBAA
            r = Double((rgb >> 24) & 0xFF) / 255.0
            g = Double((rgb >> 16) & 0xFF) / 255.0
            b = Double((rgb >> 8) & 0xFF) / 255.0
            a = Double(rgb & 0xFF) / 255.0
        default:
            return nil
        }
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }

    /// 基于某个基色，生成一套从浅到深的 4 级热力色（hex）。
    /// 通过在 HSB 空间调整饱和度与明度实现“同色系深浅”。
    /// - Parameter baseHex: 基色 hex。
    /// - Returns: 4 个 hex，index 0 最浅、index 3 = 基色本身。
    static func heatLevels(fromHex baseHex: String) -> [String] {
        #if canImport(UIKit)
        guard let base = Color(hex: baseHex) else {
            return [baseHex, baseHex, baseHex, baseHex]
        }
        let ui = UIColor(base)
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        ui.getHue(&h, saturation: &s, brightness: &b, alpha: &a)

        // 浅 → 深：降低饱和度并提高明度得到浅色，逐级回到基色。
        let factors: [(sat: CGFloat, bri: CGFloat)] = [
            (0.35, min(1.0, b + 0.30)),
            (0.60, min(1.0, b + 0.15)),
            (0.85, b),
            (1.00, max(0.0, b - 0.05))
        ]
        return factors.map { factor in
            let color = UIColor(hue: h,
                                saturation: s * factor.sat,
                                brightness: factor.bri,
                                alpha: 1.0)
            return Color(color).toHex()
        }
        #else
        return [baseHex, baseHex, baseHex, baseHex]
        #endif
    }

    /// 转为 "#RRGGBB" 字符串。
    func toHex() -> String {
        #if canImport(UIKit)
        let ui = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        ui.getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "#%02X%02X%02X",
                      Int(round(r * 255)), Int(round(g * 255)), Int(round(b * 255)))
        #else
        return "#000000"
        #endif
    }
}
