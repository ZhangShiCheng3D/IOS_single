//
//  PrivacyPolicyView.swift
//  RetroFilm
//
//  The privacy policy, shown in-app so it is always reachable — even offline,
//  which suits a 100%-local app with no backend. Linked from Settings and the
//  paywall. All copy is localized; see `privacy.*` keys in Localizable.strings.
//

import SwiftUI

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                Text("privacy.intro")
                    .font(.body)
                    .foregroundStyle(Theme.textPrimary)

                section("privacy.section.data.title", "privacy.section.data.body")
                section("privacy.section.camera.title", "privacy.section.camera.body")
                section("privacy.section.photos.title", "privacy.section.photos.body")
                section("privacy.section.purchase.title", "privacy.section.purchase.body")
                section("privacy.section.contact.title", "privacy.section.contact.body")
            }
            .padding(Theme.Spacing.xl)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle("paywall.privacy")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func section(_ titleKey: LocalizedStringKey, _ bodyKey: LocalizedStringKey) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text(titleKey)
                .font(.headline)
                .foregroundStyle(Theme.textPrimary)
            Text(bodyKey)
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    NavigationStack { PrivacyPolicyView() }
}
