//
//  SettingsView.swift
//  PixelStudio
//
//  设置：Pro 状态 / 购买入口、恢复购买、关于信息。
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var purchaseManager: PurchaseManager
    @Environment(\.dismiss) private var dismiss
    @State private var showingPaywall = false

    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if purchaseManager.isProUnlocked {
                        HStack {
                            Label("settings.proActive", systemImage: "crown.fill")
                                .foregroundStyle(.orange)
                            Spacer()
                            Image(systemName: "checkmark.seal.fill").foregroundStyle(.green)
                        }
                    } else {
                        Button {
                            showingPaywall = true
                        } label: {
                            Label("settings.unlockPro", systemImage: "crown.fill")
                        }
                    }
                    Button {
                        Task { await purchaseManager.restorePurchases() }
                    } label: {
                        Label("paywall.restore", systemImage: "arrow.clockwise")
                    }
                } header: {
                    Text("settings.purchase")
                }

                Section("settings.about") {
                    LabeledContent("settings.version", value: appVersion)
                    NavigationLink {
                        PrivacyPolicyView()
                    } label: {
                        Label("paywall.privacy", systemImage: "hand.raised")
                    }
                    Link(destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!) {
                        Label("paywall.terms", systemImage: "doc.text")
                    }
                }

                Section {
                    Text("settings.footer")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
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
                PaywallView()
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(PurchaseManager())
}
