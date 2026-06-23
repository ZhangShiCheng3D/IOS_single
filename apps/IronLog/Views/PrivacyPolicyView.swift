//
//  PrivacyPolicyView.swift
//  IronLog
//
//  App 内隐私政策。IronLog 纯本地运行、无后端、无账号，
//  因此政策核心即「数据不离开设备」。在 App 内可直接查看（上架合规要求）。
//

import SwiftUI

/// 法律 / 联系相关的固定链接。集中管理，便于上架前替换为正式地址。
enum AppLinks {
    /// 使用条款：采用 Apple 标准 EULA（无自定义条款时的合规默认值）。
    static let termsOfUse = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    /// 支持邮箱。上架前请替换为开发者真实邮箱。
    static let support = URL(string: "mailto:support@ironlog.app")!
}

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Space.xl) {
                VStack(alignment: .leading, spacing: Theme.Space.sm) {
                    Text("privacy.title")
                        .font(.largeTitle.bold())
                    Text("privacy.updated")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Text("privacy.intro")
                    .font(.callout)
                    .foregroundStyle(.secondary)

                section("privacy.section.collect.title", "privacy.section.collect.body")
                section("privacy.section.health.title", "privacy.section.health.body")
                section("privacy.section.purchase.title", "privacy.section.purchase.body")
                section("privacy.section.notify.title", "privacy.section.notify.body")
                section("privacy.section.contact.title", "privacy.section.contact.body")
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle("settings.privacy")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func section(_ titleKey: LocalizedStringKey, _ bodyKey: LocalizedStringKey) -> some View {
        VStack(alignment: .leading, spacing: Theme.Space.sm) {
            Text(titleKey)
                .font(.headline)
            Text(bodyKey)
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    NavigationStack {
        PrivacyPolicyView()
    }
}
