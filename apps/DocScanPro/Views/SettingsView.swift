//
//  SettingsView.swift
//  DocScanPro
//
//  设置页：专业版状态、外观、扫描/OCR 偏好、隐私声明、关于。
//

import SwiftUI

struct SettingsView: View {

    /// 展示付费墙回调。
    var onShowPaywall: () -> Void

    @EnvironmentObject private var purchaseManager: PurchaseManager
    @EnvironmentObject private var appSettings: AppSettings

    var body: some View {
        NavigationStack {
            Form {
                proSection
                appearanceSection
                scanSection
                privacySection
                aboutSection
            }
            .navigationTitle("tab.settings")
        }
    }

    // MARK: - Sections

    @ViewBuilder
    private var proSection: some View {
        Section {
            if purchaseManager.isPro {
                HStack {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(.green)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("settings.pro.active.title")
                            .font(.headline)
                        Text("settings.pro.active.subtitle")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                Button {
                    Haptics.tapLight()
                    onShowPaywall()
                } label: {
                    HStack {
                        Image(systemName: "crown.fill")
                            .foregroundStyle(.yellow)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("settings.pro.upgrade.title")
                                .font(.headline)
                                .foregroundStyle(.primary)
                            Text("settings.pro.upgrade.subtitle")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }

            Button("settings.pro.restore") {
                Task { await purchaseManager.restorePurchases() }
            }
        }
    }

    private var appearanceSection: some View {
        Section("settings.section.appearance") {
            Picker("settings.appearance", selection: appearanceBinding) {
                ForEach(ColorSchemePreference.allCases) { pref in
                    Text(pref.localizedTitle).tag(pref)
                }
            }
        }
    }

    private var scanSection: some View {
        Section {
            Toggle("settings.autoOCR", isOn: $appSettings.autoRunOCR)
            Toggle("settings.pdfTextLayer", isOn: $appSettings.includeTextLayerInPDF)
            VStack(alignment: .leading) {
                Text("settings.imageQuality")
                Slider(value: $appSettings.jpegQuality, in: 0.5...1.0, step: 0.1) {
                    Text("settings.imageQuality")
                } minimumValueLabel: {
                    Text("settings.quality.low").font(.caption2)
                } maximumValueLabel: {
                    Text("settings.quality.high").font(.caption2)
                }
            }
        } header: {
            Text("settings.section.scan")
        } footer: {
            Text("settings.section.scan.footer")
        }
    }

    private var privacySection: some View {
        Section("settings.section.privacy") {
            NavigationLink {
                PrivacyView()
            } label: {
                Label("settings.privacy.statement", systemImage: "lock.shield.fill")
            }
        }
    }

    private var aboutSection: some View {
        Section("settings.section.about") {
            HStack {
                Text("settings.version")
                Spacer()
                Text(appVersion)
                    .foregroundStyle(.secondary)
            }
            Link(destination: AppLinks.support) {
                Label("settings.support", systemImage: "questionmark.circle")
            }
        }
    }

    // MARK: - Helpers

    private var appearanceBinding: Binding<ColorSchemePreference> {
        Binding(
            get: { appSettings.colorSchemePreference },
            set: { appSettings.colorSchemePreference = $0 }
        )
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}

#Preview {
    SettingsView(onShowPaywall: {})
        .environmentObject(PurchaseManager.shared)
        .environmentObject(AppSettings())
}
