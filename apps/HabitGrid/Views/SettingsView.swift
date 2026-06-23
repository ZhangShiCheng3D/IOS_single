//
//  SettingsView.swift
//  HabitGrid
//
//  设置：主题/配色、外观、通知、Pro 状态、关于。
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ThemeManager.self) private var themeManager
    @Environment(PurchaseManager.self) private var purchaseManager

    @State private var showingPaywall = false
    @State private var showingThemePicker = false

    var body: some View {
        NavigationStack {
            Form {
                // MARK: Pro 状态
                Section {
                    if purchaseManager.isPro {
                        HStack {
                            Label("settings.proActive", systemImage: "checkmark.seal.fill")
                                .foregroundStyle(themeManager.palette.accent)
                            Spacer()
                            Text("settings.proBadge")
                                .font(.caption.weight(.bold))
                                .padding(.horizontal, 8).padding(.vertical, 3)
                                .background(themeManager.palette.accent.opacity(0.15), in: Capsule())
                                .foregroundStyle(themeManager.palette.accent)
                        }
                    } else {
                        Button {
                            showingPaywall = true
                        } label: {
                            HStack {
                                Label("settings.upgrade", systemImage: "sparkles")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                }

                // MARK: 外观
                Section("settings.appearance") {
                    Picker("settings.appearance", selection: appearanceBinding) {
                        ForEach(AppearancePreference.allCases) { pref in
                            Text(pref.displayName).tag(pref)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // MARK: 主题配色
                Section("settings.theme") {
                    Button {
                        showingThemePicker = true
                    } label: {
                        HStack {
                            Text("settings.colorTheme")
                                .foregroundStyle(.primary)
                            Spacer()
                            HStack(spacing: 3) {
                                ForEach(themeManager.palette.levels, id: \.self) { hex in
                                    Circle().fill(Color(hex: hex) ?? .gray).frame(width: 14, height: 14)
                                }
                            }
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.tertiary)
                        }
                    }
                }

                // MARK: 通知
                Section {
                    Button("settings.openNotificationSettings") {
                        openSystemSettings()
                    }
                } header: {
                    Text("settings.notifications")
                } footer: {
                    Text("settings.notifications.footer")
                }

                // MARK: 关于
                Section("settings.about") {
                    LabeledContent("settings.version", value: appVersion)
                    NavigationLink {
                        PrivacyPolicyView()
                    } label: {
                        Text("settings.privacy")
                    }
                    Link(destination: LegalLinks.appleStandardEULA) {
                        HStack {
                            Text("settings.terms")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.tertiary)
                        }
                    }
                    if !purchaseManager.isPro {
                        Button("paywall.restore") {
                            Task { await purchaseManager.restore() }
                        }
                    }
                }
            }
            .navigationTitle("settings.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.done") { dismiss() }
                }
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView(reason: .general)
            }
            .sheet(isPresented: $showingThemePicker) {
                ThemePickerView()
            }
        }
    }

    private var appearanceBinding: Binding<AppearancePreference> {
        Binding(
            get: { themeManager.appearance },
            set: { themeManager.appearance = $0; Haptics.selection() }
        )
    }

    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }

    private func openSystemSettings() {
        #if canImport(UIKit)
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
        #endif
    }
}

#Preview("Settings") {
    SettingsView()
        .environment(ThemeManager())
        .environment(PurchaseManager())
}
