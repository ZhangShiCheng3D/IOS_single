//
//  SettingsView.swift
//  ShotFrame
//
//  About, purchase status, and restore. Kept intentionally small — ShotFrame
//  is a focused single-purpose tool.
//

import SwiftUI

struct SettingsView: View {

    @EnvironmentObject private var purchases: PurchaseManager
    @Environment(\.dismiss) private var dismiss

    @State private var showPaywall = false

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    var body: some View {
        NavigationStack {
            List {
                proSection
                purchaseSection
                aboutSection
            }
            .navigationTitle("settings.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("common.done") { dismiss() }
                }
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }

    @ViewBuilder
    private var proSection: some View {
        Section {
            if purchases.isPro {
                HStack {
                    Label("settings.pro.active", systemImage: "checkmark.seal.fill")
                        .foregroundStyle(.green)
                    Spacer()
                }
            } else {
                Button {
                    showPaywall = true
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: "crown.fill")
                            .font(.title3)
                            .foregroundStyle(.white)
                            .frame(width: 40, height: 40)
                            .background(.orange.gradient, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("settings.pro.title").font(.headline)
                            Text("settings.pro.subtitle").font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").font(.caption).foregroundStyle(.secondary)
                    }
                }
                .foregroundStyle(.primary)
            }
        }
    }

    private var purchaseSection: some View {
        Section {
            Button("settings.restore") {
                Task { await purchases.restore() }
            }
        } footer: {
            Text("settings.restore.footer")
        }
    }

    private var aboutSection: some View {
        Section("settings.about") {
            LabeledContent("settings.version", value: appVersion)
            Link(destination: AppLinks.privacy) {
                Label("paywall.privacy", systemImage: "hand.raised")
            }
            Link(destination: AppLinks.terms) {
                Label("paywall.terms", systemImage: "doc.text")
            }
            Link(destination: AppLinks.support) {
                Label("settings.contact", systemImage: "envelope")
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(PurchaseManager())
}
