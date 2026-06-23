//
//  Extensions.swift
//  ShotFrame
//
//  Small, focused helpers used across the app.
//

import SwiftUI
import UIKit

// MARK: - Haptics

/// `UIFeedbackGenerator` and its subclasses are `@MainActor`-isolated in the
/// iOS 17 SDK, so the whole helper must be too — otherwise every call site is a
/// Swift 6 "main actor-isolated API in a nonisolated context" error.
@MainActor
enum Haptics {
    static func tap() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
    static func warning() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }
    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }
}

// MARK: - UIImage helpers

extension UIImage {
    /// Aspect ratio (width / height); falls back to 1 for zero-height images.
    var aspectRatio: CGFloat {
        size.height > 0 ? size.width / size.height : 1
    }

    /// A downscaled copy whose longest edge is `maxDimension` points, preserving
    /// aspect ratio. Used to keep editor previews snappy with huge screenshots.
    func downscaled(maxDimension: CGFloat) -> UIImage {
        let longest = max(size.width, size.height)
        guard longest > maxDimension else { return self }
        let scale = maxDimension / longest
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        return UIGraphicsImageRenderer(size: newSize, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}

// MARK: - View helpers

extension View {
    /// Applies a transform only when `condition` is true.
    @ViewBuilder
    func applyIf<Content: View>(
        _ condition: Bool,
        transform: (Self) -> Content
    ) -> some View {
        if condition { transform(self) } else { self }
    }

    /// Rounded "card" surface used throughout the control panels.
    func cardStyle(_ cornerRadius: CGFloat = 16) -> some View {
        self
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

// MARK: - Comparable

extension Comparable {
    /// Clamp the value into a closed range.
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
