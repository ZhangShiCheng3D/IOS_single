//
//  PrivacyPolicyView.swift
//  PixelStudio
//
//  App 内隐私政策。PixelStudio 纯本地运行、不收集任何数据，因此政策极简且
//  随 App 内置，无需外部 URL —— 既满足「隐私政策在 App 内可访问」的审核要求，
//  也避免占位域名。
//

import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss

    /// 是否以独立 sheet 呈现（付费墙里用），决定是否显示关闭按钮。
    var presentedAsSheet: Bool = false

    private let sections: [(titleKey: LocalizedStringKey, bodyKey: LocalizedStringKey)] = [
        ("privacy.section.collection.title", "privacy.section.collection.body"),
        ("privacy.section.storage.title", "privacy.section.storage.body"),
        ("privacy.section.photos.title", "privacy.section.photos.body"),
        ("privacy.section.purchases.title", "privacy.section.purchases.body"),
        ("privacy.section.contact.title", "privacy.section.contact.body")
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppMetrics.spacingXL) {
                VStack(alignment: .leading, spacing: AppMetrics.spacingS) {
                    Text("privacy.intro")
                        .font(.body)
                    Text("privacy.lastUpdated")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                ForEach(sections.indices, id: \.self) { index in
                    let section = sections[index]
                    VStack(alignment: .leading, spacing: AppMetrics.spacingXS) {
                        Text(section.titleKey)
                            .font(.headline)
                        Text(section.bodyKey)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(AppMetrics.spacingL)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("privacy.title")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if presentedAsSheet {
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        PrivacyPolicyView()
    }
}
