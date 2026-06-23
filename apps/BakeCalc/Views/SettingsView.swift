//
//  SettingsView.swift
//  BakeCalc
//
//  设置页。展示专业版状态、购买/恢复入口、关于信息。
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var purchaseManager: PurchaseManager
    @State private var showPaywall = false

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    var body: some View {
        List {
            Section {
                if purchaseManager.isPro {
                    HStack {
                        Label("settings.pro_active", systemImage: "crown.fill")
                            .foregroundStyle(Color.bcAccent)
                        Spacer()
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(.green)
                    }
                } else {
                    Button {
                        showPaywall = true
                    } label: {
                        Label("settings.upgrade", systemImage: "crown.fill")
                    }
                }

                Button {
                    Haptics.tap()
                    Task { await purchaseManager.restorePurchases() }
                } label: {
                    Label("settings.restore", systemImage: "arrow.clockwise")
                }
                .disabled(purchaseManager.isLoading)
            } header: {
                Text("settings.purchase")
            }

            Section("settings.about") {
                LabeledContent("settings.version", value: appVersion)
                Link(destination: URL(string: "https://www.apple.com/legal/privacy/")!) {
                    Label("settings.privacy", systemImage: "hand.raised.fill")
                }
                Link(destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!) {
                    Label("settings.terms", systemImage: "doc.text.fill")
                }
            }

            Section {
                Text("settings.credit")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle(Text("settings.title"))
        .sheet(isPresented: $showPaywall) {
            PaywallView().environmentObject(purchaseManager)
        }
        .alert(
            Text("common.notice"),
            isPresented: Binding(
                get: { purchaseManager.lastError != nil },
                set: { if !$0 { purchaseManager.lastError = nil } }
            )
        ) {
            Button("common.ok", role: .cancel) { purchaseManager.lastError = nil }
        } message: {
            Text(purchaseManager.lastError ?? "")
        }
    }
}

#Preview("设置") {
    NavigationStack {
        SettingsView()
    }
    .environmentObject(PurchaseManager())
}
