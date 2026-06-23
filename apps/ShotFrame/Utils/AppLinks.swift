//
//  AppLinks.swift
//  ShotFrame
//
//  Single source of truth for the app's external legal / support URLs, so the
//  paywall and settings never drift apart. ShotFrame is fully local and collects
//  no data; the privacy/support entries below are the only outward links.
//

import Foundation

enum AppLinks {

    /// Terms of Use. Apple's standard EULA is a valid, hosted default that
    /// satisfies App Review for a single non-consumable unlock.
    static let terms = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!

    /// Privacy policy. ShotFrame collects no data, but App Store Connect still
    /// requires a reachable URL — host this page before submission.
    static let privacy = URL(string: "https://shotframe.app/privacy")!

    /// Support contact. Replace with your real support inbox before submission.
    static let support = URL(string: "mailto:support@shotframe.app")!
}
