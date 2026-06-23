//
//  SettingsView.swift
//  IronLog
//
//  设置：单位、休息计时、HealthKit、Pro 状态、关于与法律信息。
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var purchaseManager: PurchaseManager
    @ObservedObject private var healthKit = HealthKitManager.shared

    @State private var showPaywall = false

    /// 休息时长可选项（秒）。
    private let restOptions = [30, 45, 60, 90, 120, 150, 180, 240, 300]

    var body: some View {
        NavigationStack {
            Form {
                proSection
                unitSection
                restSection
                healthSection
                aboutSection
            }
            .navigationTitle("tab.settings")
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }

    // MARK: - Pro

    @ViewBuilder
    private var proSection: some View {
        Section {
            if purchaseManager.isPro {
                HStack {
                    Label("settings.pro.active", systemImage: "checkmark.seal.fill")
                        .foregroundStyle(Color.ironAccent)
                    Spacer()
                    Text("settings.pro.thanks")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                Button {
                    showPaywall = true
                } label: {
                    HStack {
                        Image(systemName: "crown.fill")
                            .foregroundStyle(.yellow)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("settings.pro.upgrade")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(.primary)
                            Text("settings.pro.upgrade.sub")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                Button("paywall.restore") {
                    Task { await purchaseManager.restore() }
                }
                .font(.subheadline)
            }
        }
    }

    // MARK: - 单位

    private var unitSection: some View {
        Section("settings.units") {
            Picker("settings.weight.unit", selection: Binding(
                get: { settings.weightUnit },
                set: { settings.weightUnit = $0 }
            )) {
                ForEach(WeightUnit.allCases) { unit in
                    Text(unit.symbol).tag(unit)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    // MARK: - 休息计时

    private var restSection: some View {
        Section("settings.rest") {
            Picker("settings.rest.default", selection: $settings.defaultRestSeconds) {
                ForEach(restOptions, id: \.self) { seconds in
                    Text(Fmt.timer(TimeInterval(seconds))).tag(seconds)
                }
            }
            Toggle("settings.rest.auto", isOn: $settings.autoStartRestTimer)
        }
    }

    // MARK: - HealthKit

    @ViewBuilder
    private var healthSection: some View {
        if healthKit.isAvailable {
            Section {
                Toggle("settings.health.sync", isOn: $settings.syncToHealthKit)
                    .onChange(of: settings.syncToHealthKit) { _, enabled in
                        if enabled {
                            Task { await healthKit.requestAuthorization() }
                        }
                    }
            } header: {
                Text("settings.health")
            } footer: {
                Text("settings.health.footer")
            }
        }
    }

    // MARK: - 关于

    private var aboutSection: some View {
        Section("settings.about") {
            LabeledContent("settings.version", value: appVersion)
            NavigationLink {
                PrivacyPolicyView()
            } label: {
                Label("settings.privacy", systemImage: "hand.raised")
            }
            Link(destination: AppLinks.termsOfUse) {
                Label("settings.terms", systemImage: "doc.text")
            }
            Link(destination: AppLinks.support) {
                Label("settings.contact", systemImage: "envelope")
            }
        }
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppSettings())
        .environmentObject(PurchaseManager())
        .modelContainer(PreviewData.container)
}
