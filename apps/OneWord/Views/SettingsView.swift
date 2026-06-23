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
    @Environment(NotificationManager.self) private var reminders
    @Environment(HealthManager.self) private var health
    @Environment(\.modelContext) private var context
    @Query private var entries: [DiaryEntry]

    /// Opt-in iCloud sync. Read at launch by the app; changes take effect on
    /// the next launch (SwiftData builds its container once).
    @AppStorage("icloud.sync") private var iCloudSync = false

    @State private var showingPaywall = false
    @State private var showingPasscodeSetup = false
    @State private var showingShare = false
    @State private var shareURL: URL?
    @State private var exportError = false
    @State private var showingPrivacy = false
    @State private var reminderDenied = false
    @State private var healthDenied = false

    private let exporter = ExportManager()

    var body: some View {
        NavigationStack {
            Form {
                premiumSection
                reminderSection
                syncSection
                privacySection
                dataSection
                aboutSection
                #if DEBUG
                debugSection
                #endif
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

    // MARK: Reminders

    private var reminderSection: some View {
        Section {
            Toggle(isOn: reminderBinding) {
                Label("settings.dailyReminder", systemImage: "bell.badge")
            }
            if reminders.isEnabled {
                DatePicker(
                    "settings.reminderTime",
                    selection: Binding(
                        get: { reminders.time },
                        set: { reminders.time = $0 }
                    ),
                    displayedComponents: .hourAndMinute
                )
            }
        } header: {
            Text("settings.reminders")
        } footer: {
            Text("settings.reminderFooter")
        }
        .alert("settings.reminderDenied", isPresented: $reminderDenied) {
            Button("common.ok", role: .cancel) {}
        }
    }

    /// Turning the reminder on requests notification permission; if denied the
    /// toggle reverts and a one-shot alert explains why.
    private var reminderBinding: Binding<Bool> {
        Binding(
            get: { reminders.isEnabled },
            set: { newValue in
                if newValue {
                    Task {
                        await reminders.enable()
                        if reminders.permissionDenied { reminderDenied = true }
                    }
                } else {
                    reminders.disable()
                }
            }
        )
    }

    // MARK: Sync & Health

    @ViewBuilder
    private var syncSection: some View {
        Section {
            if health.isAvailable {
                Toggle(isOn: healthBinding) {
                    Label("settings.healthSync", systemImage: "heart.fill")
                }
            }
            Toggle(isOn: $iCloudSync) {
                Label("settings.icloudSync", systemImage: "icloud.fill")
            }
        } header: {
            Text("settings.sync")
        } footer: {
            Text(iCloudSync ? "settings.icloudRestart" : "settings.syncFooter")
        }
        .alert("settings.healthDenied", isPresented: $healthDenied) {
            Button("common.ok", role: .cancel) {}
        }
    }

    /// Enabling Health requests write authorization; denial reverts + alerts.
    private var healthBinding: Binding<Bool> {
        Binding(
            get: { health.isEnabled },
            set: { newValue in
                if newValue {
                    Task {
                        await health.enable()
                        if health.permissionDenied { healthDenied = true }
                    }
                } else {
                    health.disable()
                }
            }
        )
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

    // MARK: Debug (test builds only)

    #if DEBUG
    private var debugSection: some View {
        Section {
            Toggle(isOn: Binding(
                get: { store.debugForceUnlocked },
                set: { store.debugSetUnlocked($0) }
            )) {
                Label("Unlock AI Insights (test)", systemImage: "wrench.and.screwdriver")
            }
            Button {
                seedSampleData()
            } label: {
                Label("Load sample year of entries", systemImage: "tray.and.arrow.down")
            }
            Button(role: .destructive) {
                deleteAllEntries()
            } label: {
                Label("Delete all entries", systemImage: "trash")
            }
            .disabled(entries.isEmpty)
        } header: {
            Text("Debug — not in release")
        } footer: {
            Text("Test-only tools to exercise the insight suite without a StoreKit purchase. Compiled out of release builds.")
        }
    }

    private func seedSampleData() { DebugSeed.seed(into: context, existing: entries) }
    private func deleteAllEntries() { DebugSeed.clear(entries, in: context) }
    #endif

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
        .environment(NotificationManager())
        .environment(HealthManager())
        .modelContainer(PreviewData.container)
}
