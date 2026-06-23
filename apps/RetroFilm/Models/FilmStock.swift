//
//  FilmStock.swift
//  RetroFilm
//
//  Defines the catalog of film stocks (emulations) the app offers.
//  Each `FilmStock` is a value-type recipe consumed by `FilmFilterEngine`.
//  Stocks are intentionally pure data — no UIKit / CoreImage imports here —
//  so they can be encoded into SwiftData and previewed cheaply.
//

import Foundation
import SwiftUI

/// A single film-emulation recipe. The numeric fields drive the Core Image
/// pipeline in `FilmFilterEngine`. Values are tuned to *look* like the named
/// stock rather than to be colorimetrically exact.
struct FilmStock: Identifiable, Hashable, Codable {

    let id: String                 // stable identifier, also used as the SwiftData key
    let displayName: String        // localized via Localizable.strings key == id
    let shortLabel: String         // 2–4 char badge shown on the filter wheel
    let isPremium: Bool            // gated behind the paywall when true

    // MARK: Color science
    var temperature: Double        // white-balance shift, Kelvin offset (-) cool / (+) warm
    var tint: Double               // green(-)/magenta(+) bias
    var saturation: Double         // 1.0 == neutral
    var contrast: Double           // 1.0 == neutral
    var brightness: Double         // additive exposure, 0 == neutral

    // MARK: Tone curve (lifted shadows / rolled highlights = the "film" feel)
    var shadowLift: Double         // 0...1, how much to raise the black point
    var highlightRolloff: Double   // 0...1, how much to compress highlights
    var fade: Double               // 0...1, overall matte/faded milkiness

    // MARK: Split toning (shadows vs highlights get different hues)
    var shadowTint: RGBColor       // color pushed into shadows
    var highlightTint: RGBColor    // color pushed into highlights
    var toningStrength: Double     // 0...1

    // MARK: Texture defaults (user-overridable per shot)
    var grainAmount: Double        // 0...1 default grain intensity
    var vignetteAmount: Double     // 0...1 default vignette darkness
    var lightLeakAmount: Double    // 0...1 default light-leak intensity
    var isMonochrome: Bool         // true for B&W stocks

    /// SwiftUI accent used on the wheel badge.
    var swatch: Color { Color(red: highlightTint.r, green: highlightTint.g, blue: highlightTint.b) }
}

/// Plain Codable RGB triple (0...1). Avoids storing non-Codable `Color`.
struct RGBColor: Hashable, Codable {
    var r: Double, g: Double, b: Double
    init(_ r: Double, _ g: Double, _ b: Double) { self.r = r; self.g = g; self.b = b }
    static let clear = RGBColor(0, 0, 0)
}

// MARK: - Catalog

extension FilmStock {

    /// The full built-in catalog. The first entries are free; premium stocks
    /// are unlocked by the in-app purchase handled in `PurchaseManager`.
    static let catalog: [FilmStock] = [
        original, kodakGold, portra400, fujiSuperia, ilfordHP5,
        kodakUltramax, portra800, fujiPro400H, cinestill800T, agfaVista, polaroidSX70
    ]

    /// Stocks available without purchase.
    static var freeStocks: [FilmStock] { catalog.filter { !$0.isPremium } }

    static func stock(for id: String) -> FilmStock {
        catalog.first { $0.id == id } ?? original
    }

    // MARK: Free

    static let original = FilmStock(
        id: "film.original", displayName: "Original", shortLabel: "—", isPremium: false,
        temperature: 0, tint: 0, saturation: 1.0, contrast: 1.0, brightness: 0,
        shadowLift: 0, highlightRolloff: 0, fade: 0,
        shadowTint: .clear, highlightTint: RGBColor(0.5, 0.5, 0.5), toningStrength: 0,
        grainAmount: 0.0, vignetteAmount: 0.0, lightLeakAmount: 0.0, isMonochrome: false
    )

    static let kodakGold = FilmStock(
        id: "film.kodakGold", displayName: "Kodak Gold", shortLabel: "GOLD", isPremium: false,
        temperature: 380, tint: 6, saturation: 1.12, contrast: 1.06, brightness: 0.02,
        shadowLift: 0.10, highlightRolloff: 0.22, fade: 0.08,
        shadowTint: RGBColor(0.16, 0.12, 0.02), highlightTint: RGBColor(0.98, 0.86, 0.55), toningStrength: 0.35,
        grainAmount: 0.28, vignetteAmount: 0.22, lightLeakAmount: 0.0, isMonochrome: false
    )

    static let portra400 = FilmStock(
        id: "film.portra400", displayName: "Portra 400", shortLabel: "P400", isPremium: false,
        temperature: 160, tint: 2, saturation: 0.94, contrast: 0.95, brightness: 0.03,
        shadowLift: 0.16, highlightRolloff: 0.30, fade: 0.14,
        shadowTint: RGBColor(0.05, 0.08, 0.12), highlightTint: RGBColor(0.98, 0.90, 0.82), toningStrength: 0.40,
        grainAmount: 0.20, vignetteAmount: 0.16, lightLeakAmount: 0.0, isMonochrome: false
    )

    static let fujiSuperia = FilmStock(
        id: "film.fujiSuperia", displayName: "Fuji Superia", shortLabel: "FUJI", isPremium: false,
        temperature: -120, tint: -10, saturation: 1.16, contrast: 1.08, brightness: 0,
        shadowLift: 0.08, highlightRolloff: 0.20, fade: 0.06,
        shadowTint: RGBColor(0.0, 0.10, 0.08), highlightTint: RGBColor(0.82, 0.95, 0.88), toningStrength: 0.42,
        grainAmount: 0.26, vignetteAmount: 0.20, lightLeakAmount: 0.0, isMonochrome: false
    )

    static let ilfordHP5 = FilmStock(
        id: "film.ilfordHP5", displayName: "Ilford HP5", shortLabel: "B&W", isPremium: false,
        temperature: 0, tint: 0, saturation: 0.0, contrast: 1.18, brightness: 0.02,
        shadowLift: 0.06, highlightRolloff: 0.18, fade: 0.05,
        shadowTint: .clear, highlightTint: RGBColor(0.9, 0.9, 0.9), toningStrength: 0,
        grainAmount: 0.42, vignetteAmount: 0.24, lightLeakAmount: 0.0, isMonochrome: true
    )

    // MARK: Premium

    static let kodakUltramax = FilmStock(
        id: "film.kodakUltramax", displayName: "Kodak Ultramax", shortLabel: "UMAX", isPremium: true,
        temperature: 300, tint: 10, saturation: 1.22, contrast: 1.10, brightness: 0,
        shadowLift: 0.09, highlightRolloff: 0.18, fade: 0.05,
        shadowTint: RGBColor(0.14, 0.06, 0.02), highlightTint: RGBColor(1.0, 0.82, 0.60), toningStrength: 0.45,
        grainAmount: 0.34, vignetteAmount: 0.22, lightLeakAmount: 0.10, isMonochrome: false
    )

    static let portra800 = FilmStock(
        id: "film.portra800", displayName: "Portra 800", shortLabel: "P800", isPremium: true,
        temperature: 220, tint: 4, saturation: 1.0, contrast: 1.02, brightness: 0.01,
        shadowLift: 0.18, highlightRolloff: 0.28, fade: 0.12,
        shadowTint: RGBColor(0.08, 0.04, 0.10), highlightTint: RGBColor(1.0, 0.88, 0.78), toningStrength: 0.40,
        grainAmount: 0.40, vignetteAmount: 0.18, lightLeakAmount: 0.06, isMonochrome: false
    )

    static let fujiPro400H = FilmStock(
        id: "film.fujiPro400H", displayName: "Fuji Pro 400H", shortLabel: "400H", isPremium: true,
        temperature: -80, tint: -6, saturation: 0.96, contrast: 0.94, brightness: 0.04,
        shadowLift: 0.20, highlightRolloff: 0.32, fade: 0.18,
        shadowTint: RGBColor(0.02, 0.10, 0.10), highlightTint: RGBColor(0.86, 0.96, 0.90), toningStrength: 0.46,
        grainAmount: 0.22, vignetteAmount: 0.14, lightLeakAmount: 0.0, isMonochrome: false
    )

    static let cinestill800T = FilmStock(
        id: "film.cinestill800T", displayName: "CineStill 800T", shortLabel: "800T", isPremium: true,
        temperature: -260, tint: -4, saturation: 1.05, contrast: 1.06, brightness: 0,
        shadowLift: 0.14, highlightRolloff: 0.16, fade: 0.08,
        shadowTint: RGBColor(0.0, 0.06, 0.18), highlightTint: RGBColor(0.78, 0.86, 1.0), toningStrength: 0.50,
        grainAmount: 0.36, vignetteAmount: 0.20, lightLeakAmount: 0.16, isMonochrome: false
    )

    static let agfaVista = FilmStock(
        id: "film.agfaVista", displayName: "Agfa Vista", shortLabel: "VSTA", isPremium: true,
        temperature: 120, tint: 14, saturation: 1.28, contrast: 1.12, brightness: 0,
        shadowLift: 0.07, highlightRolloff: 0.16, fade: 0.04,
        shadowTint: RGBColor(0.14, 0.0, 0.06), highlightTint: RGBColor(1.0, 0.84, 0.74), toningStrength: 0.44,
        grainAmount: 0.30, vignetteAmount: 0.22, lightLeakAmount: 0.08, isMonochrome: false
    )

    static let polaroidSX70 = FilmStock(
        id: "film.polaroidSX70", displayName: "Polaroid SX-70", shortLabel: "SX70", isPremium: true,
        temperature: 200, tint: -8, saturation: 0.88, contrast: 0.90, brightness: 0.05,
        shadowLift: 0.26, highlightRolloff: 0.34, fade: 0.30,
        shadowTint: RGBColor(0.06, 0.10, 0.04), highlightTint: RGBColor(0.96, 0.92, 0.80), toningStrength: 0.48,
        grainAmount: 0.18, vignetteAmount: 0.10, lightLeakAmount: 0.0, isMonochrome: false
    )
}
