//
//  HapticManager.swift
//  RetroFilm
//
//  Thin wrapper around UIFeedbackGenerator so the rest of the app can request
//  haptics without re-creating generators or worrying about availability.
//

import UIKit

enum HapticManager {

    /// A light tap — used when scrolling the filter wheel onto a new stock.
    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }

    /// A firm thunk — the shutter press.
    static func shutter() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }

    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func warning() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }
}
