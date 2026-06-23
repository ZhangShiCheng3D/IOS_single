//
//  PasscodeSetupView.swift
//  OneWord
//
//  Two-step 4-digit passcode creation (enter + confirm). On success it sets
//  the passcode and enables the lock.
//

import SwiftUI

struct PasscodeSetupView: View {
    @Environment(AppLock.self) private var appLock
    @Environment(\.dismiss) private var dismiss

    @State private var first = ""
    @State private var confirm = ""
    @State private var stage: Stage = .enter
    @State private var mismatch = false

    private let length = 4

    enum Stage { case enter, confirm }

    private var current: String {
        stage == .enter ? first : confirm
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: Theme.Spacing.xl) {
                Spacer()
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(Theme.accent)
                Text(stage == .enter ? "passcode.create" : "passcode.confirm")
                    .font(.title3.bold())

                HStack(spacing: Theme.Spacing.md) {
                    ForEach(0..<length, id: \.self) { i in
                        Circle()
                            .fill(i < current.count ? Theme.accent : Color.gray.opacity(0.3))
                            .frame(width: 16, height: 16)
                            .scaleEffect(i < current.count ? 1.15 : 1)
                    }
                }
                .animation(.spring(response: 0.25, dampingFraction: 0.6), value: current.count)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("a11y.passcodeProgress")
                .accessibilityValue(String(current.count))

                if mismatch {
                    Text("passcode.mismatch")
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                Spacer()
                keypad
            }
            .padding(Theme.Spacing.lg)
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("settings.changePasscode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel") { dismiss() }
                }
            }
        }
    }

    private var keypad: some View {
        let keys: [[String]] = [
            ["1", "2", "3"], ["4", "5", "6"], ["7", "8", "9"], ["", "0", "⌫"]
        ]
        return VStack(spacing: Theme.Spacing.md) {
            ForEach(keys, id: \.self) { row in
                HStack(spacing: Theme.Spacing.xl) {
                    ForEach(row, id: \.self) { key in
                        if key.isEmpty {
                            Color.clear.frame(width: 72, height: 72)
                        } else {
                            Button { handle(key) } label: {
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
                }
            }
        }
    }

    private func handle(_ key: String) {
        mismatch = false
        if key == "⌫" {
            if stage == .enter, !first.isEmpty { first.removeLast(); Haptics.tap() }
            if stage == .confirm, !confirm.isEmpty { confirm.removeLast(); Haptics.tap() }
            return
        }
        Haptics.tap()

        if stage == .enter {
            guard first.count < length else { return }
            first.append(key)
            if first.count == length { stage = .confirm }
        } else {
            guard confirm.count < length else { return }
            confirm.append(key)
            if confirm.count == length { finish() }
        }
    }

    private func finish() {
        if first == confirm {
            Haptics.success()
            appLock.setPasscode(first)
            appLock.isEnabled = true
            dismiss()
        } else {
            Haptics.error()
            mismatch = true
            first = ""
            confirm = ""
            stage = .enter
        }
    }
}

#Preview {
    PasscodeSetupView()
        .environment(AppLock())
}
