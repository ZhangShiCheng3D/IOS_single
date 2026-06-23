//
//  Theme.swift
//  OneWord
//
//  Central design tokens: colors, spacing, corner radii, and reusable
//  view modifiers so the visual language stays consistent app-wide.
//

import SwiftUI

enum Theme {

    // MARK: Colors (resolved from the asset catalog for light/dark support)
    static let background = Color("AppBackground")
    static let card = Color("CardBackground")
    static let accent = Color("AccentColor")
    static let textPrimary = Color("TextPrimary")
    static let textSecondary = Color("TextSecondary")

    // MARK: Spacing scale
    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
    }

    // MARK: Corner radii
    enum Radius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
    }
}

// MARK: - Card styling

struct CardModifier: ViewModifier {
    var padding: CGFloat = Theme.Spacing.md

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Theme.card)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

extension View {
    /// Wraps content in the standard rounded card surface.
    func cardStyle(padding: CGFloat = Theme.Spacing.md) -> some View {
        modifier(CardModifier(padding: padding))
    }
}

// MARK: - Primary button style

struct PrimaryButtonStyle: ButtonStyle {
    var enabled: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                    .fill(enabled ? Theme.accent : Color.gray)
            )
            .opacity(configuration.isPressed ? 0.8 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}
