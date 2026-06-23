//
//  PrivacyPolicyView.swift
//  FastFlow
//
//  App 内隐私政策。FastFlow 为纯本地 App，不收集、不上传任何数据；
//  此页面让用户随时可在 App 内查阅隐私说明（满足上架要求）。
//

import SwiftUI

struct PrivacyPolicyView: View {
    /// 政策分节：(标题 key, 正文 key)。
    private let sections: [(title: String, body: String)] = [
        ("privacy.section.local.title", "privacy.section.local.body"),
        ("privacy.section.health.title", "privacy.section.health.body"),
        ("privacy.section.notifications.title", "privacy.section.notifications.body"),
        ("privacy.section.purchases.title", "privacy.section.purchases.body"),
        ("privacy.section.thirdparty.title", "privacy.section.thirdparty.body")
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Spacing.lg) {
                VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                    Text("privacy.intro")
                        .font(.body)
                        .foregroundStyle(.secondary)
                    Text("privacy.updated")
                        .font(.footnote)
                        .foregroundStyle(.tertiary)
                }

                ForEach(sections, id: \.title) { section in
                    VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                        Text(LocalizedStringKey(section.title))
                            .font(.headline)
                        Text(LocalizedStringKey(section.body))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(DS.Spacing.lg)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("settings.about.privacy")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        PrivacyPolicyView()
    }
}
