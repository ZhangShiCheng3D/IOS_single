//
//  SettingsView.swift
//  RetroFilm
//
//  App settings + the purchase entry point and restore. Also surfaces version
//  info and links required for App Store review (privacy, terms).
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: PurchaseManager
    @Environment(\.dismiss) private var dismiss
    @State private var showPaywall = false

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    var body: some View {
        NavigationStack {
            List {
                purchaseSection
                aboutSection
                legalSection
            }
            .navigationTitle("settings.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("action.done") { dismiss() }.bold()
                }
            }
            .sheet(isPresented: $showPaywall) { PaywallView().environmentObject(store) }
        }
    }

    private var purchaseSection: some View {
        Section {
            if store.isUnlocked {
                Label("settings.unlocked", systemImage: "checkmark.seal.fill")
                    .foregroundStyle(.green)
            } else {
                Button {
                    showPaywall = true
                } label: {
                    HStack {
                        Label("settings.unlockAll", systemImage: "lock.open.fill")
                        Spacer()
                        Text(store.formattedPrice).foregroundStyle(.secondary)
                    }
                }
            }
            Button("paywall.restore") { Task { await store.restore() } }
        } header: {
            Text("settings.section.purchase")
        }
    }

    private var aboutSection: some View {
        Section {
            HStack {
                Text("settings.version")
                Spacer()
                Text(appVersion).foregroundStyle(.secondary)
            }
            HStack {
                Text("settings.filmCount")
                Spacer()
                Text("\(FilmStock.catalog.count)").foregroundStyle(.secondary)
            }
        } header: {
            Text("settings.section.about")
        } footer: {
            Text("settings.privacy.note")
        }
    }

    private var legalSection: some View {
        Section {
            NavigationLink {
                PrivacyPolicyView()
            } label: {
                Label("paywall.privacy", systemImage: "hand.raised.fill")
            }
            Link(destination: Legal.termsURL) {
                Label("paywall.terms", systemImage: "doc.text.fill")
            }
        } header: {
            Text("settings.section.legal")
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(PurchaseManager())
}
