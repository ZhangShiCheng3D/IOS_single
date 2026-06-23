//
//  LockView.swift
//  OneWord
//
//  Full-screen privacy gate shown when the lock is enabled. Offers biometric
//  unlock and a 4-digit passcode keypad fallback.
//

import SwiftUI

struct LockView: View {
    @Environment(AppLock.self) private var appLock

    @State private var entered = ""
    @State private var showError = false

    private let passcodeLength = 4

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: Theme.Spacing.xl) {
                Spacer()

                VStack(spacing: Theme.Spacing.md) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(Theme.accent)
                    Text("app.name").font(.title.bold())
                    Text("lock.prompt")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                passcodeDots

                if showError {
                    Text("lock.wrong")
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                Spacer()

                keypad

                if appLock.biometricsEnabled {
                    Button {
                        Task { await tryBiometrics() }
                    } label: {
                        Label("lock.useBiometrics", systemImage: biometryIcon)
                            .font(.subheadline)
                    }
                    .padding(.bottom, Theme.Spacing.lg)
                }
            }
            .padding(Theme.Spacing.lg)
        }
        .task {
            // Offer biometrics immediately on appearance.
            await tryBiometrics()
        }
    }

    private var passcodeDots: some View {
        HStack(spacing: Theme.Spacing.md) {
            ForEach(0..<passcodeLength, id: \.self) { index in
                Circle()
                    .fill(index < entered.count ? Theme.accent : Color.gray.opacity(0.3))
                    .frame(width: 16, height: 16)
                    .scaleEffect(index < entered.count ? 1.15 : 1)
            }
        }
        .animation(.spring(response: 0.25, dampingFraction: 0.6), value: entered.count)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("a11y.passcodeProgress")
        .accessibilityValue(String(entered.count))
    }

    private var keypad: some View {
        let keys: [[String]] = [
            ["1", "2", "3"],
            ["4", "5", "6"],
            ["7", "8", "9"],
            ["", "0", "⌫"]
        ]
        return VStack(spacing: Theme.Spacing.md) {
            ForEach(keys, id: \.self) { row in
                HStack(spacing: Theme.Spacing.xl) {
                    ForEach(row, id: \.self) { key in
                        keypadButton(key)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func keypadButton(_ key: String) -> some View {
        if key.isEmpty {
            Color.clear.frame(width: 72, height: 72)
        } else {
            Button {
                handleKey(key)
            } label: {
                Text(key)
                    .font(.title)
                    .frame(width: 72, height: 72)
                    .background(Circle().fill(Theme.card))
                    .foregroundStyle(Theme.textPrimary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(key == "⌫" ? Text("a11y.delete") : Text(key))
        }
    }

    private var biometryIcon: String {
        switch appLock.biometryType {
        case .faceID: return "faceid"
        case .touchID: return "touchid"
        default: return "lock.open"
        }
    }

    // MARK: Actions

    private func handleKey(_ key: String) {
        showError = false
        if key == "⌫" {
            if !entered.isEmpty {
                Haptics.tap()
                entered.removeLast()
            }
            return
        }
        guard entered.count < passcodeLength else { return }
        Haptics.tap()
        entered.append(key)

        if entered.count == passcodeLength {
            if appLock.validate(passcode: entered) {
                Haptics.success()
                appLock.unlockWithoutAuth()
            } else {
                Haptics.error()
                showError = true
                entered = ""
            }
        }
    }

    private func tryBiometrics() async {
        _ = await appLock.authenticateWithBiometrics()
    }
}

#Preview {
    LockView()
        .environment(AppLock())
}
