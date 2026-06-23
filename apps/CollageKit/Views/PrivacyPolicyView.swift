//
//  PrivacyPolicyView.swift
//  CollageKit
//
//  App 内隐私政策。CollageKit 为纯本地应用，不收集、不上传任何数据，
//  在此明确告知用户，满足 App Store 对「隐私政策可在 App 内访问」的要求。
//

import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("privacy_intro")
                        .font(.body)

                    section("privacy_data_title", "privacy_data_body")
                    section("privacy_photos_title", "privacy_photos_body")
                    section("privacy_purchase_title", "privacy_purchase_body")
                    section("privacy_contact_title", "privacy_contact_body")

                    Text("privacy_updated")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
            }
            .navigationTitle("paywall_privacy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("done") { dismiss() }
                }
            }
        }
    }

    private func section(_ title: LocalizedStringKey, _ body: LocalizedStringKey) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.headline)
            Text(body).font(.subheadline).foregroundStyle(.secondary)
        }
    }
}

#Preview {
    PrivacyPolicyView()
}
