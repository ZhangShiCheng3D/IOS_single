//
//  ShotTemplate.swift
//  ShotFrame
//
//  Built-in, hand-tuned templates. Templates are the core aesthetic asset of the
//  app, so each one is a complete `ShotSettings` recipe with a curated palette.
//

import SwiftUI

/// A named, reusable look. Applying a template overwrites the styling parts of
/// `ShotSettings` while leaving the user's annotations intact.
struct ShotTemplate: Identifiable, Hashable {
    let id: String
    let name: LocalizedStringKey
    /// Colors shown in the gallery swatch (top→bottom).
    let swatch: [RGBAColor]
    /// Whether this template requires the Pro unlock.
    let isPro: Bool
    /// The styling this template applies.
    let settings: ShotSettings

    static func == (lhs: ShotTemplate, rhs: ShotTemplate) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

enum TemplateLibrary {

    /// Helper to build a gradient background config.
    private static func gradient(_ hexes: [String], angle: Double = 135) -> BackgroundConfig {
        BackgroundConfig(
            kind: .gradient,
            gradientColors: hexes.map { RGBAColor(hex: $0) },
            gradientAngle: angle
        )
    }

    private static func solid(_ hex: String) -> BackgroundConfig {
        BackgroundConfig(kind: .solid, solidColor: RGBAColor(hex: hex))
    }

    /// The full catalogue. The first three are free; the rest unlock with Pro.
    static let all: [ShotTemplate] = [

        // ---- Free ----
        ShotTemplate(
            id: "sunset",
            name: "tpl.sunset",
            swatch: [RGBAColor(hex: "FF9A9E"), RGBAColor(hex: "FAD0C4")],
            isPro: false,
            settings: ShotSettings(
                background: gradient(["FF9A9E", "FAD0C4", "FBC2EB"], angle: 120),
                deviceFrame: .none,
                aspect: .portrait,
                padding: 0.10, cornerRadius: 0.05, shadowRadius: 0.035, shadowOpacity: 0.30
            )
        ),
        ShotTemplate(
            id: "clean",
            name: "tpl.clean",
            swatch: [RGBAColor(hex: "FFFFFF"), RGBAColor(hex: "F2F2F7")],
            isPro: false,
            settings: ShotSettings(
                background: gradient(["FFFFFF", "EDEFF3"], angle: 160),
                deviceFrame: .none,
                aspect: .square,
                padding: 0.09, cornerRadius: 0.045, shadowRadius: 0.04, shadowOpacity: 0.18
            )
        ),
        ShotTemplate(
            id: "midnight",
            name: "tpl.midnight",
            swatch: [RGBAColor(hex: "232526"), RGBAColor(hex: "414345")],
            isPro: false,
            settings: ShotSettings(
                background: gradient(["0F2027", "203A43", "2C5364"], angle: 145),
                deviceFrame: .iPhone,
                aspect: .portrait,
                padding: 0.11, cornerRadius: 0.05, shadowRadius: 0.05, shadowOpacity: 0.5
            )
        ),

        // ---- Pro ----
        ShotTemplate(
            id: "ocean",
            name: "tpl.ocean",
            swatch: [RGBAColor(hex: "2193B0"), RGBAColor(hex: "6DD5ED")],
            isPro: true,
            settings: ShotSettings(
                background: gradient(["2193B0", "6DD5ED"], angle: 130),
                deviceFrame: .iPhone,
                aspect: .portrait,
                padding: 0.12, cornerRadius: 0.05, shadowRadius: 0.045, shadowOpacity: 0.4
            )
        ),
        ShotTemplate(
            id: "aurora",
            name: "tpl.aurora",
            swatch: [RGBAColor(hex: "A18CD1"), RGBAColor(hex: "FBC2EB")],
            isPro: true,
            settings: ShotSettings(
                background: gradient(["A18CD1", "FBC2EB", "8EC5FC"], angle: 115),
                deviceFrame: .none,
                aspect: .square,
                padding: 0.10, cornerRadius: 0.05, shadowRadius: 0.04, shadowOpacity: 0.3
            )
        ),
        ShotTemplate(
            id: "coral",
            name: "tpl.coral",
            swatch: [RGBAColor(hex: "FF6E7F"), RGBAColor(hex: "BFE9FF")],
            isPro: true,
            settings: ShotSettings(
                background: gradient(["FF6E7F", "BFE9FF"], angle: 140),
                deviceFrame: .none,
                aspect: .portrait,
                padding: 0.11, cornerRadius: 0.05, shadowRadius: 0.04, shadowOpacity: 0.32
            )
        ),
        ShotTemplate(
            id: "forest",
            name: "tpl.forest",
            swatch: [RGBAColor(hex: "134E5E"), RGBAColor(hex: "71B280")],
            isPro: true,
            settings: ShotSettings(
                background: gradient(["134E5E", "71B280"], angle: 150),
                deviceFrame: .iPhone,
                aspect: .portrait,
                padding: 0.12, cornerRadius: 0.05, shadowRadius: 0.05, shadowOpacity: 0.45
            )
        ),
        ShotTemplate(
            id: "lavender",
            name: "tpl.lavender",
            swatch: [RGBAColor(hex: "D9AFD9"), RGBAColor(hex: "97D9E1")],
            isPro: true,
            settings: ShotSettings(
                background: gradient(["D9AFD9", "97D9E1"], angle: 125),
                deviceFrame: .none,
                aspect: .square,
                padding: 0.10, cornerRadius: 0.05, shadowRadius: 0.035, shadowOpacity: 0.28
            )
        ),
        ShotTemplate(
            id: "slate",
            name: "tpl.slate",
            swatch: [RGBAColor(hex: "3E5151"), RGBAColor(hex: "DECBA4")],
            isPro: true,
            settings: ShotSettings(
                background: gradient(["3E5151", "DECBA4"], angle: 135),
                deviceFrame: .macBook,
                aspect: .landscape,
                padding: 0.08, cornerRadius: 0.02, shadowRadius: 0.05, shadowOpacity: 0.4
            )
        ),
        ShotTemplate(
            id: "peachy",
            name: "tpl.peachy",
            swatch: [RGBAColor(hex: "FFECD2"), RGBAColor(hex: "FCB69F")],
            isPro: true,
            settings: ShotSettings(
                background: gradient(["FFECD2", "FCB69F"], angle: 160),
                deviceFrame: .none,
                aspect: .portrait,
                padding: 0.11, cornerRadius: 0.05, shadowRadius: 0.04, shadowOpacity: 0.25
            )
        ),
        ShotTemplate(
            id: "mono",
            name: "tpl.mono",
            swatch: [RGBAColor(hex: "141E30"), RGBAColor(hex: "243B55")],
            isPro: true,
            settings: ShotSettings(
                background: gradient(["141E30", "243B55"], angle: 145),
                deviceFrame: .browser,
                aspect: .landscape,
                padding: 0.07, cornerRadius: 0.02, shadowRadius: 0.05, shadowOpacity: 0.5
            )
        ),
        ShotTemplate(
            id: "blush",
            name: "tpl.blush",
            swatch: [RGBAColor(hex: "FAD0C4"), RGBAColor(hex: "FFD1FF")],
            isPro: true,
            settings: ShotSettings(
                background: gradient(["FAD0C4", "FFD1FF"], angle: 120),
                deviceFrame: .iPhone,
                aspect: .story,
                padding: 0.14, cornerRadius: 0.06, shadowRadius: 0.05, shadowOpacity: 0.3
            )
        ),
        ShotTemplate(
            id: "graphite",
            name: "tpl.graphite",
            swatch: [RGBAColor(hex: "0F0C29"), RGBAColor(hex: "302B63")],
            isPro: true,
            settings: ShotSettings(
                background: gradient(["0F0C29", "302B63", "24243E"], angle: 135),
                deviceFrame: .none,
                aspect: .story,
                padding: 0.12, cornerRadius: 0.06, shadowRadius: 0.05, shadowOpacity: 0.5
            )
        ),
        ShotTemplate(
            id: "frost",
            name: "tpl.frost",
            swatch: [RGBAColor(hex: "E0EAFC"), RGBAColor(hex: "CFDEF3")],
            isPro: true,
            settings: ShotSettings(
                background: .init(kind: .blurredImage, blurRadius: 45, overlayDarkness: 0.05),
                deviceFrame: .none,
                aspect: .square,
                padding: 0.09, cornerRadius: 0.05, shadowRadius: 0.04, shadowOpacity: 0.3
            )
        ),
    ]

    static let free = all.filter { !$0.isPro }
    static let pro = all.filter { $0.isPro }

    static func template(id: String) -> ShotTemplate? {
        all.first { $0.id == id }
    }
}
