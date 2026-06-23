//
//  AppLock.swift
//  OneWord
//
//  Privacy lock for the journal. Supports Face ID / Touch ID via LocalAuthentication
//  with a 4-digit passcode fallback stored as a salted hash in UserDefaults.
//  The passcode itself is never stored in plaintext.
//

import Foundation
import LocalAuthentication
import CryptoKit
import Observation

@MainActor
@Observable
final class AppLock {

    /// Whether the lock feature is enabled by the user.
    var isEnabled: Bool {
        didSet { defaults.set(isEnabled, forKey: Keys.enabled) }
    }

    /// Whether biometric unlock is preferred when available.
    var biometricsEnabled: Bool {
        didSet { defaults.set(biometricsEnabled, forKey: Keys.biometrics) }
    }

    /// Runtime lock state. When `true` the content is hidden behind LockView.
    var isLocked: Bool

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let enabled = "lock.enabled"
        static let biometrics = "lock.biometrics"
        static let passcodeHash = "lock.passcodeHash"
    }

    init() {
        let enabled = defaults.bool(forKey: Keys.enabled)
        self.isEnabled = enabled
        self.biometricsEnabled = defaults.object(forKey: Keys.biometrics) as? Bool ?? true
        // Start locked if the feature is on so the journal isn't exposed at launch.
        self.isLocked = enabled
    }

    // MARK: - Passcode management

    var hasPasscode: Bool {
        defaults.string(forKey: Keys.passcodeHash) != nil
    }

    /// Stores a salted SHA-256 hash of the passcode. Never stores plaintext.
    func setPasscode(_ code: String) {
        defaults.set(hash(code), forKey: Keys.passcodeHash)
    }

    /// Clears the passcode and disables the lock.
    func removePasscode() {
        defaults.removeObject(forKey: Keys.passcodeHash)
        isEnabled = false
        isLocked = false
    }

    /// Validates a candidate passcode against the stored hash.
    func validate(passcode: String) -> Bool {
        guard let stored = defaults.string(forKey: Keys.passcodeHash) else { return false }
        return stored == hash(passcode)
    }

    private func hash(_ code: String) -> String {
        // Static app salt + per-install differentiation is overkill for a 4-digit
        // local passcode; a salted SHA-256 keeps the value opaque at rest.
        let salted = "OneWord.salt.v1:" + code
        let digest = SHA256.hash(data: Data(salted.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    // MARK: - Locking

    func lock() {
        guard isEnabled else { return }
        isLocked = true
    }

    func unlockWithoutAuth() {
        isLocked = false
    }

    // MARK: - Biometrics

    /// The kind of biometric available, for labeling buttons appropriately.
    var biometryType: LABiometryType {
        let context = LAContext()
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        return context.biometryType
    }

    /// Attempts Face ID / Touch ID unlock. Calls back on the main actor.
    func authenticateWithBiometrics() async -> Bool {
        guard biometricsEnabled else { return false }

        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            return false
        }

        let reason = String(localized: "lock.biometricReason")
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: reason
            )
            if success {
                Haptics.success()
                isLocked = false
            }
            return success
        } catch {
            return false
        }
    }
}
