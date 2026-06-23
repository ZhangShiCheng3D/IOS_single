//
//  Theme.swift
//  RetroFilm
//
//  Centralized design tokens. Colors come from the asset catalog so they adapt
//  to light/dark mode automatically; this file gives them semantic names plus a
//  small, consistent system of spacing / radius / motion / elevation constants
//  so every view shares the same visual rhythm (a 4pt grid).
//

import SwiftUI

enum Theme {

    // MARK: Colors (backed by Assets.xcassets color sets)
    static let accent = Color("AccentColor")
    static let filmBackground = Color("FilmBackground")
    static let surface = Color("Surface")
    static let textPrimary = Color("TextPrimary")
    static let textSecondary = Color("TextSecondary")

    // A warm "kodak" gradient used on the paywall and capture flash.
    static let warmGradient = LinearGradient(
        colors: [Color(red: 0.98, green: 0.62, blue: 0.20),
                 Color(red: 0.90, green: 0.32, blue: 0.28)],
        startPoint: .topLeading, endPoint: .bottomTrailing)

    // MARK: Layout
    static let cornerRadius: CGFloat = 16
    static let filmStripHeight: CGFloat = 96
    static let shutterSize: CGFloat = 76

    /// 4pt spacing grid. Use these instead of ad-hoc numbers so padding stays
    /// consistent across the whole app.
    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
    }

    /// Corner-radius scale. `medium` matches the legacy `cornerRadius`.
    enum Radius {
        static let small: CGFloat = 10
        static let medium: CGFloat = 16
        static let large: CGFloat = 22
        static let pill: CGFloat = 999
    }

    /// Shared motion curves so transitions feel like one app, not many.
    enum Motion {
        static let spring = Animation.spring(response: 0.35, dampingFraction: 0.8)
        static let snappy = Animation.spring(response: 0.25, dampingFraction: 0.75)
        static let gentle = Animation.easeInOut(duration: 0.25)
    }

    // MARK: Typography
    static func displayFont(_ size: CGFloat) -> Font {
        .system(size: size, weight: .semibold, design: .rounded)
    }
}

// MARK: - Reusable view modifiers

/// Frosted card surface used across sheets and panels.
struct CardBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
            .softShadow()
    }
}

/// A soft, low-opacity elevation shadow. Deliberately gentle so the UI feels
/// calm rather than "floating" — tuned for both light and dark mode.
struct SoftShadow: ViewModifier {
    var radius: CGFloat = 14
    var y: CGFloat = 6
    func body(content: Content) -> some View {
        content.shadow(color: .black.opacity(0.18), radius: radius, x: 0, y: y)
    }
}

extension View {
    func cardBackground() -> some View { modifier(CardBackground()) }
    func softShadow(radius: CGFloat = 14, y: CGFloat = 6) -> some View {
        modifier(SoftShadow(radius: radius, y: y))
    }
}

// MARK: - Legal links

/// Single source of truth for the app's legal URLs. The privacy policy is
/// shown in-app (see `PrivacyPolicyView`) so it works offline; terms point to
/// Apple's standard EULA, which is acceptable for App Review when an app uses
/// the default license agreement.
enum Legal {
    static let termsURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
}
