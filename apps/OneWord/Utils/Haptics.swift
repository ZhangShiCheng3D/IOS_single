//
//  Haptics.swift
//  OneWord
//
//  Tiny wrapper around UIKit's feedback generators so interactions across the
//  app feel tactile and native. Centralized here so call sites stay one-liners.
//

import UIKit

@MainActor
enum Haptics {

    /// Light tick for selection changes (mood picker, segmented choices).
    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }

    /// A discrete tap, e.g. each digit on the passcode keypad.
    static func tap(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    /// Confirms a completed action (saved an entry, unlocked, purchased).
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    /// Soft caution (pending purchase, recoverable issue).
    static func warning() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }

    /// Signals a failed attempt (wrong passcode, mismatch).
    static func error() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }
}
