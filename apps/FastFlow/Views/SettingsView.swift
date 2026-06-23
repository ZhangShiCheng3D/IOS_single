//
//  SettingsView.swift
//  FastFlow
//
//  设置页：高级解锁入口、喝水提醒、HealthKit、通知权限、关于。
//

import SwiftUI

struct SettingsView: View {
    @Environment(PurchaseManager.self) private var purchaseManager

    // 喝水提醒设置（持久化于 UserDefaults）。
    @AppStorage("fastflow.reminder.enabled") private var waterReminderEnabled = false
    @AppStorage("fastflow.reminder.startHour") private var startHour = 9
    @AppStorage("fastflow.reminder.endHour") private var endHour = 21
    @AppStorage("fastflow.reminder.interval") private var intervalHours = 2

    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            Form {
                premiumSection
                waterReminderSection
                healthSection
                aboutSection
            }
            .navigationTitle("tab.settings")
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }

    // MARK: - 高级解锁

    private var premiumSection: some View {
        Section {
            if purchaseManager.isPremiumUnlocked {
                HStack {
                    Label("settings.premium.active", systemImage: "checkmark.seal.fill")
                        .foregroundStyle(Color.goalReached)
                    Spacer()
                }
            } else {
                Button {
                    showPaywall = true
                } label: {
                    HStack {
                        Label("settings.premium.unlock", systemImage: "sparkles")
                        Spacer()
                        Text(purchaseManager.premiumDisplayPrice)
                            .foregroundStyle(.secondary)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                Button("settings.premium.restore") {
                    Task { await purchaseManager.restorePurchases() }
                }
                .font(.subheadline)
            }
        } header: {
            Text("settings.section.premium")
        }
    }

    // MARK: - 喝水提醒

    private var waterReminderSection: some View {
        Section {
            Toggle("settings.reminder.enable", isOn: $waterReminderEnabled)
                .onChange(of: waterReminderEnabled) { _, _ in applyReminders() }

            if waterReminderEnabled {
                Stepper(value: $startHour, in: 0...22) {
                    settingRow(titleKey: "settings.reminder.start", value: "\(startHour):00")
                }
                .onChange(of: startHour) { _, _ in applyReminders() }

                Stepper(value: $endHour, in: (startHour + 1)...23) {
                    settingRow(titleKey: "settings.reminder.end", value: "\(endHour):00")
                }
                .onChange(of: endHour) { _, _ in applyReminders() }

                Stepper(value: $intervalHours, in: 1...6) {
                    settingRow(
                        titleKey: "settings.reminder.interval",
                        value: String(format: NSLocalizedString("settings.reminder.everyHours", comment: ""), intervalHours)
                    )
                }
                .onChange(of: intervalHours) { _, _ in applyReminders() }
            }
        } header: {
            Text("settings.section.reminder")
        } footer: {
            Text("settings.reminder.footer")
        }
    }

    // MARK: - HealthKit

    private var healthSection: some View {
        Section {
            Button {
                Task { await HealthKitManager.shared.requestAuthorization() }
            } label: {
                Label("settings.health.connect", systemImage: "heart.fill")
            }
        } header: {
            Text("settings.section.health")
        } footer: {
            Text("settings.health.footer")
        }
    }

    // MARK: - 关于

    private var aboutSection: some View {
        Section("settings.section.about") {
            LabeledContent("settings.about.version", value: appVersion)
            // 隐私政策内置于 App 内，离线随时可查。
            NavigationLink {
                PrivacyPolicyView()
            } label: {
                Label("settings.about.privacy", systemImage: "hand.raised.fill")
            }
            // 使用条款采用 Apple 标准 EULA。
            Link(destination: Self.termsURL) {
                Label("settings.about.terms", systemImage: "doc.text.fill")
            }
        }
    }

    /// Apple 标准最终用户许可协议（EULA）。
    private static let termsURL = URL(
        string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/"
    )!

    // MARK: - 辅助

    private func settingRow(titleKey: LocalizedStringKey, value: String) -> some View {
        HStack {
            Text(titleKey)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        return version
    }

    private func applyReminders() {
        guard waterReminderEnabled else {
            NotificationManager.shared.cancelWaterReminders()
            return
        }
        Task {
            let granted = await NotificationManager.shared.requestAuthorization()
            if granted {
                NotificationManager.shared.scheduleWaterReminders(
                    startHour: startHour,
                    endHour: endHour,
                    intervalHours: intervalHours
                )
            } else {
                waterReminderEnabled = false
            }
        }
    }
}

#Preview {
    SettingsView()
        .environment(PurchaseManager())
}
