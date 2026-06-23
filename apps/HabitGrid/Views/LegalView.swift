//
//  LegalView.swift
//  HabitGrid
//
//  App 内可访问的隐私政策（离线、本地化）。上架要求隐私政策文案在 App 内可达，
//  且不依赖外部域名解析。使用条款统一指向 Apple 标准 EULA。
//

import SwiftUI

/// 法务链接常量。集中管理，避免散落的占位 URL。
enum LegalLinks {
    /// Apple 标准最终用户许可协议（条款）。买断式 App 无自定义条款时使用此官方链接。
    static let appleStandardEULA = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
}

/// 应用内隐私政策页面。内容随系统语言本地化，完全离线可读。
struct PrivacyPolicyView: View {

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ForEach(Self.sections, id: \.titleKey) { section in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(section.titleKey)
                            .font(.headline)
                        Text(section.bodyKey)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                Text("privacy.updated")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .padding(.top, 4)
            }
            .padding(20)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("settings.privacy")
        .navigationBarTitleDisplayMode(.inline)
    }

    private struct Section {
        let titleKey: LocalizedStringKey
        let bodyKey: LocalizedStringKey
    }

    private static let sections: [Section] = [
        Section(titleKey: "privacy.section.summary.title", bodyKey: "privacy.section.summary.body"),
        Section(titleKey: "privacy.section.data.title", bodyKey: "privacy.section.data.body"),
        Section(titleKey: "privacy.section.icloud.title", bodyKey: "privacy.section.icloud.body"),
        Section(titleKey: "privacy.section.purchase.title", bodyKey: "privacy.section.purchase.body"),
        Section(titleKey: "privacy.section.notifications.title", bodyKey: "privacy.section.notifications.body"),
        Section(titleKey: "privacy.section.contact.title", bodyKey: "privacy.section.contact.body")
    ]
}

#Preview("Privacy") {
    NavigationStack {
        PrivacyPolicyView()
    }
}
