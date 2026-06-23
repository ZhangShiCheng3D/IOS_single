//
//  SettingsView.swift
//  OneWord
//
//  App settings: privacy lock configuration, premium unlock / restore,
//  data export, and about info.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(AppLock.self) private var appLock
    @Environment(PurchaseManager.self) private var store
    @Environment(\.modelContext) private var context
    @Query private var entries: [DiaryEntry]

    @State private var showingPaywall = false
    @State private var showingPasscodeSetup = false
    @State private var showingShare = false
    @State private var shareURL: URL?
    @State private var exportError = false
    @State private var showingPrivacy = false

    private let exporter = ExportManager()

    var body: some View {
        NavigationStack {
            Form {
                premiumSection
                privacySection
                dataSection
                aboutSection
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("tab.settings")
            .sheet(isPresented: $showingPaywall) { PaywallView() }
            .sheet(isPresented: $showingPasscodeSetup) {
                PasscodeSetupView()
            }
            .sheet(isPresented: $showingShare) {
                if let url = shareURL {
                    ShareSheet(items: [url])
                }
            }
            .sheet(isPresented: $showingPrivacy) { PrivacyPolicyView() }
            .alert("export.error", isPresented: $exportError) {
                Button("common.ok", role: .cancel) {}
            }
        }
    }

    // MARK: Premium

    @ViewBuilder
    private var premiumSection: some View {
        Section {
            if store.isPremiumUnlocked {
                Label("settings.premiumActive", systemImage: "checkmark.seal.fill")
                    .foregroundStyle(.green)
            } else {
                Button {
                    showingPaywall = true
                } label: {
                    Label("settings.unlockAI", systemImage: "sparkles")
                }
                Button("settings.restore") {
                    Task { await store.restore() }
                }
            }
        } header: {
            Text("settings.aiInsights")
        }
    }

    // MARK: Privacy

    @ViewBuilder
    private var privacySection: some View {
        @Bindable var lock = appLock
        Section {
            Toggle(isOn: lockBinding) {
                Label("settings.appLock", systemImage: "lock.fill")
            }
            if appLock.isEnabled {
                Toggle(isOn: $lock.biometricsEnabled) {
                    Label("settings.biometrics", systemImage: "faceid")
                }
                Button("settings.changePasscode") {
                    showingPasscodeSetup = true
                }
            }
        } header: {
            Text("settings.privacy")
        } footer: {
            Text("settings.privacyFooter")
        }
    }

    /// Enabling the lock requires setting a passcode first.
    private var lockBinding: Binding<Bool> {
        Binding(
            get: { appLock.isEnabled },
            set: { newValue in
                if newValue {
                    if appLock.hasPasscode {
                        appLock.isEnabled = true
                    } else {
                        showingPasscodeSetup = true
                    }
                } else {
                    appLock.removePasscode()
                }
            }
        )
    }

    // MARK: Data

    private var dataSection: some View {
        Section {
            Menu {
                ForEach(ExportFormat.allCases) { format in
                    Button(format.title) { export(as: format) }
                }
            } label: {
                Label("settings.export", systemImage: "square.and.arrow.up")
            }
            .disabled(entries.isEmpty)
        } header: {
            Text("settings.data")
        } footer: {
            Text("settings.exportFooter")
        }
    }

    // MARK: About

    private var aboutSection: some View {
        Section {
            HStack {
                Text("settings.version")
                Spacer()
                Text(appVersion).foregroundStyle(.secondary)
            }
            Button {
                showingPrivacy = true
            } label: {
                Label("settings.privacyPolicy", systemImage: "hand.raised.fill")
            }
            Link(destination: Legal.termsOfUseURL) {
                Label("settings.terms", systemImage: "doc.text")
            }
            Label("settings.privacyPromise", systemImage: "lock.shield")
                .foregroundStyle(.secondary)
                .font(.footnote)
        } header: {
            Text("settings.about")
        }
    }

    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        return v
    }

    // MARK: Actions

    private func export(as format: ExportFormat) {
        do {
            shareURL = try exporter.export(entries, as: format)
            showingShare = true
        } catch {
            exportError = true
        }
    }
}

#Preview {
    SettingsView()
        .environment(AppLock())
        .environment(PurchaseManager())
        .modelContainer(PreviewData.container)
}
