//
//  FilterSettings.swift
//  RetroFilm
//
//  Per-shot, user-adjustable parameters layered on top of a `FilmStock`.
//  This is the object the "滤镜参数微调" (fine-tune) UI mutates and the
//  `FilmFilterEngine` consumes alongside the chosen stock.
//

import Foundation

/// Live, tweakable settings for a single render. Multiplies/offsets the
/// stock's baked-in defaults so users can dial a look up or down.
struct FilterSettings: Equatable, Codable {

    /// 0...1 — overall strength of the film look (cross-fades toward the original).
    var intensity: Double = 1.0

    /// 0...2 — multiplies the stock's default grain.
    var grain: Double = 1.0

    /// 0...2 — multiplies the stock's default vignette.
    var vignette: Double = 1.0

    /// 0...2 — multiplies the stock's default light-leak.
    var lightLeak: Double = 1.0

    /// Additive exposure in stops-ish units, -1...1.
    var exposure: Double = 0.0

    /// Additive warmth, -1 (cool) ... 1 (warm).
    var warmth: Double = 0.0

    /// Whether to burn the date stamp into the exported image.
    var dateStampEnabled: Bool = false

    /// Which light-leak style index to use (wraps in `FilmFilterEngine`).
    var lightLeakStyle: Int = 0

    static let `default` = FilterSettings()

    /// Resets fine-tune sliders but preserves toggles the user set intentionally.
    mutating func resetAdjustments() {
        intensity = 1.0; grain = 1.0; vignette = 1.0; lightLeak = 1.0
        exposure = 0.0; warmth = 0.0
    }
}
