//
//  HealthManager.swift
//  OneWord
//
//  Optional, opt-in writing of each day's mood to Apple Health as a
//  "State of Mind" sample (iOS 17+). Write-only and entirely on-device: the
//  sample goes straight into the user's local Health store, never a server.
//

import Foundation
import HealthKit
import Observation

@MainActor
@Observable
final class HealthManager {

    private let store = HKHealthStore()
    private let enabledKey = "health.enabled"

    /// Whether the user has opted in to mirroring moods into Apple Health.
    private(set) var isEnabled: Bool
    /// Set when enabling failed (unavailable or authorization error) so
    /// Settings can surface a one-shot explanation.
    var permissionDenied = false

    /// State of Mind requires iOS 18+ *and* a device with Health data.
    var isAvailable: Bool {
        if #available(iOS 18.0, *) {
            return HKHealthStore.isHealthDataAvailable()
        }
        return false
    }

    init() {
        isEnabled = UserDefaults.standard.bool(forKey: enabledKey)
    }

    /// Requests permission to write State of Mind and enables mirroring.
    func enable() async {
        guard isAvailable, #available(iOS 18.0, *) else {
            permissionDenied = true
            return
        }
        let type = HKObjectType.stateOfMindType()
        do {
            try await store.requestAuthorization(toShare: [type], read: [])
            setEnabled(true)
            permissionDenied = false
        } catch {
            setEnabled(false)
            permissionDenied = true
        }
    }

    /// Stops mirroring. Existing Health samples are left untouched (the user
    /// owns and can delete them in the Health app).
    func disable() {
        setEnabled(false)
    }

    /// Writes one day's mood as a daily-mood State of Mind sample. The
    /// sentiment score in [-1, 1] maps directly onto State of Mind's valence.
    func saveMood(score: Double, date: Date) async {
        guard isEnabled, isAvailable, #available(iOS 18.0, *) else { return }
        let valence = max(-1, min(1, score))
        let sample = HKStateOfMind(
            date: date,
            kind: .dailyMood,
            valence: valence,
            labels: [],
            associations: []
        )
        try? await store.save(sample)
    }

    private func setEnabled(_ value: Bool) {
        isEnabled = value
        UserDefaults.standard.set(value, forKey: enabledKey)
    }
}
