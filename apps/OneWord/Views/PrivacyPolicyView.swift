//
//  PrivacyPolicyView.swift
//  OneWord
//
//  The privacy policy ships inside the app: OneWord is 100% offline, so there
//  is no website to host it on, and App Review needs it reachable in-app.
//  Also defines the canonical legal URLs used by the paywall and settings.
//

import SwiftUI

/// Shared legal endpoints. The Terms of Use point at Apple's standard EULA,
/// which is the required default for apps that don't supply their own.
enum Legal {
    static let termsOfUseURL = URL(
        string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/"
    )!
}

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    Label("privacy.heading", systemImage: "hand.raised.fill")
                        .font(.title2.bold())
                        .foregroundStyle(Theme.accent)

                    section("privacy.s1.title", "privacy.s1.body")
                    section("privacy.s2.title", "privacy.s2.body")
                    section("privacy.s3.title", "privacy.s3.body")
                    section("privacy.s4.title", "privacy.s4.body")

                    Text("privacy.updated")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.top, Theme.Spacing.sm)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(Theme.Spacing.lg)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("settings.privacyPolicy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.close") { dismiss() }
                }
            }
        }
    }

    private func section(_ title: LocalizedStringKey, _ body: LocalizedStringKey) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text(title)
                .font(.headline)
                .foregroundStyle(Theme.textPrimary)
            Text(body)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    PrivacyPolicyView()
}
