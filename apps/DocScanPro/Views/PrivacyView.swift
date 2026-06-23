//
//  PrivacyView.swift
//  DocScanPro
//
//  隐私声明页。隐私是本应用的核心卖点：零网络、零上传、纯本地。
//

import SwiftUI

struct PrivacyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                hero

                PrivacyPoint(
                    icon: "wifi.slash",
                    titleKey: "privacy.point.noNetwork.title",
                    bodyKey: "privacy.point.noNetwork.body"
                )
                PrivacyPoint(
                    icon: "iphone.and.arrow.forward",
                    titleKey: "privacy.point.onDevice.title",
                    bodyKey: "privacy.point.onDevice.body"
                )
                PrivacyPoint(
                    icon: "icloud.slash",
                    titleKey: "privacy.point.noCloud.title",
                    bodyKey: "privacy.point.noCloud.body"
                )
                PrivacyPoint(
                    icon: "hand.raised.fill",
                    titleKey: "privacy.point.noTracking.title",
                    bodyKey: "privacy.point.noTracking.body"
                )
                PrivacyPoint(
                    icon: "trash.fill",
                    titleKey: "privacy.point.youControl.title",
                    bodyKey: "privacy.point.youControl.body"
                )

                Text("privacy.footer")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.top, 8)
            }
            .padding(24)
        }
        .navigationTitle("privacy.title")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var hero: some View {
        VStack(spacing: 12) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 60))
                .foregroundStyle(Color.accentColor)
                .accessibilityHidden(true)
            Text("privacy.hero.title")
                .font(.title2.bold())
                .multilineTextAlignment(.center)
            Text("privacy.hero.subtitle")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 8)
    }
}

private struct PrivacyPoint: View {
    let icon: String
    let titleKey: LocalizedStringKey
    let bodyKey: LocalizedStringKey

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(Color.accentColor)
                .frame(width: 34)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(titleKey)
                    .font(.headline)
                Text(bodyKey)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    NavigationStack {
        PrivacyView()
    }
}
