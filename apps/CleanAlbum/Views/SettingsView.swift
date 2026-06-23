//
//  SettingsView.swift
//  CleanAlbum
//
//  设置：相似度阈值、模糊灵敏度、隐私说明、恢复购买。
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Bindable var settings: AppSettings
    @Environment(PurchaseManager.self) private var purchase
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                similaritySection
                blurSection
                privacySection
                purchaseSection
                legalSection
                aboutSection
            }
            .navigationTitle("settings.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("action.done") { dismiss() }
                }
            }
        }
    }

    private var similaritySection: some View {
        Section {
            VStack(alignment: .leading) {
                HStack {
                    Text("settings.similarity")
                    Spacer()
                    Text("\(Int(settings.similarityThreshold * 100))%")
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                Slider(value: $settings.similarityThreshold, in: 0.5...1.0, step: 0.05) {
                    Text("settings.similarity")
                } minimumValueLabel: {
                    Image(systemName: "circle.dashed")
                } maximumValueLabel: {
                    Image(systemName: "circle.fill")
                }
                .tint(.brand)
            }
        } header: {
            Text("settings.section.similarity")
        } footer: {
            Text("settings.similarity.hint")
        }
    }

    private var blurSection: some View {
        Section {
            VStack(alignment: .leading) {
                HStack {
                    Text("settings.blur")
                    Spacer()
                    Text("\(Int(settings.blurSensitivity * 100))%")
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                Slider(value: $settings.blurSensitivity, in: 0.0...1.0, step: 0.05)
                    .tint(.brand)
            }
        } header: {
            Text("settings.section.blur")
        } footer: {
            Text("settings.blur.hint")
        }
    }

    private var privacySection: some View {
        Section {
            Label("settings.privacy.local", systemImage: "iphone.gen3")
            Label("settings.privacy.noUpload", systemImage: "wifi.slash")
            Label("settings.privacy.noTracking", systemImage: "hand.raised.fill")
        } header: {
            Text("settings.section.privacy")
        } footer: {
            Text("settings.privacy.footer")
        }
    }

    private var purchaseSection: some View {
        Section {
            HStack {
                Text("settings.proStatus")
                Spacer()
                Text(purchase.isPro ? "settings.pro.unlocked" : "settings.pro.locked")
                    .foregroundStyle(purchase.isPro ? Color.positive : .secondary)
            }
            Button("paywall.restore") {
                Haptics.light()
                Task { await purchase.restore() }
            }
        } header: {
            Text("settings.section.purchase")
        }
    }

    private var legalSection: some View {
        Section {
            Link(destination: AppLinks.privacyPolicy) {
                linkRow(titleKey: "settings.privacyPolicy", systemImage: "hand.raised.fill")
            }
            Link(destination: AppLinks.termsOfUse) {
                linkRow(titleKey: "settings.termsOfUse", systemImage: "doc.text")
            }
        } header: {
            Text("settings.section.legal")
        }
    }

    private func linkRow(titleKey: LocalizedStringKey, systemImage: String) -> some View {
        HStack {
            Label(titleKey, systemImage: systemImage)
            Spacer()
            Image(systemName: "arrow.up.right")
                .font(.footnote)
                .foregroundStyle(.tertiary)
        }
        .foregroundStyle(.primary)
    }

    private var aboutSection: some View {
        Section {
            HStack {
                Text("settings.version")
                Spacer()
                Text(appVersion).foregroundStyle(.secondary)
            }
        } header: {
            Text("settings.section.about")
        }
    }

    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }
}

#Preview {
    SettingsView(settings: AppSettings())
        .environment(PurchaseManager())
}
