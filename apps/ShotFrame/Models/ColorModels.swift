//
//  ColorModels.swift
//  ShotFrame
//
//  Codable color value types so colors can live inside SwiftData / Codable settings.
//

import SwiftUI

/// A `Color` representation that can be persisted (SwiftData / JSON).
///
/// SwiftUI's `Color` is not `Codable`, so the editor stores colors as
/// normalised sRGB components and converts on demand.
struct RGBAColor: Codable, Equatable, Hashable {
    var red: Double
    var green: Double
    var blue: Double
    var opacity: Double

    init(red: Double, green: Double, blue: Double, opacity: Double = 1.0) {
        self.red = red
        self.green = green
        self.blue = blue
        self.opacity = opacity
    }

    /// Build from a SwiftUI `Color` by resolving its underlying `UIColor`.
    init(_ color: Color) {
        let ui = UIColor(color)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        ui.getRed(&r, green: &g, blue: &b, alpha: &a)
        self.red = Double(r)
        self.green = Double(g)
        self.blue = Double(b)
        self.opacity = Double(a)
    }

    /// Build from a hex string such as `#FF5733` or `FF5733`.
    init(hex: String, opacity: Double = 1.0) {
        var cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if cleaned.hasPrefix("#") { cleaned.removeFirst() }
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)
        self.red = Double((value & 0xFF0000) >> 16) / 255.0
        self.green = Double((value & 0x00FF00) >> 8) / 255.0
        self.blue = Double(value & 0x0000FF) / 255.0
        self.opacity = opacity
    }

    /// The SwiftUI color (sRGB).
    var color: Color {
        Color(.sRGB, red: red, green: green, blue: blue, opacity: opacity)
    }

    /// Uppercase hex string without the leading `#`.
    var hexString: String {
        String(
            format: "%02X%02X%02X",
            Int((red * 255).rounded()),
            Int((green * 255).rounded()),
            Int((blue * 255).rounded())
        )
    }

    /// Relative luminance, used to pick legible foreground colors.
    var luminance: Double {
        0.2126 * red + 0.7152 * green + 0.0722 * blue
    }

    static let white = RGBAColor(red: 1, green: 1, blue: 1)
    static let black = RGBAColor(red: 0, green: 0, blue: 0)
}
