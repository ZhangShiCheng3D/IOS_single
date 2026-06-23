//
//  SettingsView.swift
//  CollageKit
//
//  设置页：Pro 状态、恢复购买、关于与法律信息。
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: PurchaseManager
    @Environment(\.dismiss) private var dismiss
    @State private var showPaywall = false
    @State private var showPrivacy = false

    /// Apple 标准最终用户许可协议（EULA）。
    private let termsURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    /// 支持邮箱。上架前请替换为正式的开发者支持邮箱。
    private let supportURL = URL(string: "mailto:Cricketzwc@californiamail.com")!

    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if store.isPro {
                        HStack {
                            Label("settings_pro_active", systemImage: "crown.fill")
                                .foregroundStyle(Color.accentColor)
                            Spacer()
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundStyle(Color.accentColor)
                        }
                    } else {
                        Button {
                            showPaywall = true
                        } label: {
                            HStack {
                                Label("settings_unlock_pro", systemImage: "crown.fill")
                                Spacer()
                                Text(store.proDisplayPrice).foregroundStyle(.secondary)
                                Image(systemName: "chevron.right").foregroundStyle(.tertiary)
                            }
                        }
                    }
                    Button("settings_restore") {
                        Task { await store.restore() }
                    }
                } header: {
                    Text("settings_section_pro")
                }

                Section {
                    Button {
                        showPrivacy = true
                    } label: {
                        Label("paywall_privacy", systemImage: "hand.raised")
                    }
                    Link(destination: termsURL) {
                        Label("paywall_terms", systemImage: "doc.text")
                    }
                    Link(destination: supportURL) {
                        Label("settings_contact", systemImage: "envelope")
                    }
                } header: {
                    Text("settings_section_about")
                }

                Section {
                    HStack {
                        Text("settings_version")
                        Spacer()
                        Text(appVersion).foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("settings_title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("done") { dismiss() }
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView().environmentObject(store)
            }
            .sheet(isPresented: $showPrivacy) {
                PrivacyPolicyView()
            }
        }
    }
}

#Preview {
    SettingsView().environmentObject(PurchaseManager())
}
