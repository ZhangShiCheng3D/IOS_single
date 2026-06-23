//
//  ShotSettings.swift
//  ShotFrame
//
//  The full editing recipe for a single screenshot. Everything that defines how
//  the exported image looks lives here so it can be persisted and re-applied.
//

import SwiftUI

// MARK: - Background

/// The kind of canvas background behind the screenshot.
enum BackgroundKind: String, Codable, CaseIterable, Identifiable {
    case solid
    case gradient
    case blurredImage   // a blurred copy of the screenshot itself
    case image          // a user supplied photo

    var id: String { rawValue }

    var displayName: LocalizedStringKey {
        switch self {
        case .solid: return "bg.solid"
        case .gradient: return "bg.gradient"
        case .blurredImage: return "bg.blurred"
        case .image: return "bg.image"
        }
    }

    var systemImage: String {
        switch self {
        case .solid: return "paintpalette"
        case .gradient: return "circle.lefthalf.filled"
        case .blurredImage: return "drop.halffull"
        case .image: return "photo"
        }
    }
}

/// Configuration for the canvas background.
struct BackgroundConfig: Codable, Equatable {
    var kind: BackgroundKind = .gradient
    var solidColor: RGBAColor = RGBAColor(hex: "F2F2F7")
    var gradientColors: [RGBAColor] = [RGBAColor(hex: "FF9A9E"), RGBAColor(hex: "FAD0C4")]
    /// Gradient angle in degrees, 0 = top→bottom, increasing clockwise.
    var gradientAngle: Double = 135
    /// Blur applied when `kind == .blurredImage`.
    var blurRadius: Double = 40
    /// Dim overlay applied over blurred / photo backgrounds (0…1).
    var overlayDarkness: Double = 0.1

    /// SwiftUI gradient built from the stored stops.
    var gradient: LinearGradient {
        let angle = Angle(degrees: gradientAngle)
        let start = UnitPoint(
            x: 0.5 - cos(angle.radians) * 0.5,
            y: 0.5 - sin(angle.radians) * 0.5
        )
        let end = UnitPoint(
            x: 0.5 + cos(angle.radians) * 0.5,
            y: 0.5 + sin(angle.radians) * 0.5
        )
        return LinearGradient(
            colors: gradientColors.map(\.color),
            startPoint: start,
            endPoint: end
        )
    }
}

// MARK: - Device frame

/// The mockup shell drawn around the screenshot.
enum DeviceFrameType: String, Codable, CaseIterable, Identifiable {
    case none
    case iPhone
    case iPad
    case macBook
    case browser   // a lightweight browser window chrome

    var id: String { rawValue }

    var displayName: LocalizedStringKey {
        switch self {
        case .none: return "frame.none"
        case .iPhone: return "frame.iphone"
        case .iPad: return "frame.ipad"
        case .macBook: return "frame.macbook"
        case .browser: return "frame.browser"
        }
    }

    var systemImage: String {
        switch self {
        case .none: return "rectangle"
        case .iPhone: return "iphone"
        case .iPad: return "ipad"
        case .macBook: return "macbook"
        case .browser: return "macwindow"
        }
    }

    /// Whether choosing this frame is gated behind the Pro purchase.
    var isPro: Bool {
        switch self {
        case .none, .iPhone: return false
        default: return true
        }
    }
}

// MARK: - Canvas aspect

/// Output aspect ratio of the whole canvas.
enum CanvasAspect: String, Codable, CaseIterable, Identifiable {
    case auto       // follow the screenshot's own ratio (with padding)
    case square     // 1:1
    case portrait   // 4:5  (Instagram feed)
    case story      // 9:16 (Stories / Reels)
    case landscape  // 16:9 (Twitter / OG image)

    var id: String { rawValue }

    var displayName: LocalizedStringKey {
        switch self {
        case .auto: return "aspect.auto"
        case .square: return "aspect.square"
        case .portrait: return "aspect.portrait"
        case .story: return "aspect.story"
        case .landscape: return "aspect.landscape"
        }
    }

    var systemImage: String {
        switch self {
        case .auto: return "wand.and.stars"
        case .square: return "square"
        case .portrait: return "rectangle.portrait"
        case .story: return "rectangle.portrait.fill"
        case .landscape: return "rectangle"
        }
    }

    /// width / height, or nil for `.auto`.
    var ratio: CGFloat? {
        switch self {
        case .auto: return nil
        case .square: return 1
        case .portrait: return 4.0 / 5.0
        case .story: return 9.0 / 16.0
        case .landscape: return 16.0 / 9.0
        }
    }
}

// MARK: - Annotation

/// A text label overlaid on the canvas. Position is stored relative (0…1) so it
/// survives resizing / re-export at any resolution.
struct Annotation: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var text: String = "Tap to edit"
    /// Centre point in 0…1 canvas coordinates.
    var position: CGPoint = CGPoint(x: 0.5, y: 0.12)
    /// Font size relative to canvas width (0…1). 0.06 ≈ a comfortable headline.
    var fontScale: Double = 0.06
    var color: RGBAColor = .white
    var isBold: Bool = true
    var hasShadow: Bool = true
}

// MARK: - Settings root

/// The complete, persistable description of one edited shot.
struct ShotSettings: Codable, Equatable {
    var background = BackgroundConfig()
    var deviceFrame: DeviceFrameType = .none
    var aspect: CanvasAspect = .auto

    /// Padding around the screenshot as a fraction of the canvas's shorter side.
    var padding: Double = 0.08
    /// Screenshot corner radius as a fraction of the screenshot's shorter side.
    var cornerRadius: Double = 0.04
    /// Drop-shadow strength (blur) as a fraction of the canvas's shorter side.
    var shadowRadius: Double = 0.03
    var shadowOpacity: Double = 0.35

    var annotations: [Annotation] = []

    /// A sensible default used for brand-new projects.
    static let `default` = ShotSettings()
}
