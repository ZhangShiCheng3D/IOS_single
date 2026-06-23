//
//  SettingsView.swift
//  PaperGames
//
//  设置页。外观（深色/大字号）、游戏辅助选项、购买管理与关于。
//

import SwiftUI

struct SettingsView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(PurchaseManager.self) private var store
    @State private var showPaywall = false

    var body: some View {
        @Bindable var settings = settings

        NavigationStack {
            Form {
                // MARK: 外观
                Section("settings.section.appearance") {
                    Picker(selection: $settings.colorScheme) {
                        ForEach(AppColorScheme.allCases) { scheme in
                            Text(scheme.titleKey).tag(scheme)
                        }
                    } label: {
                        Label("settings.appearance.theme", systemImage: "circle.lefthalf.filled")
                    }

                    Toggle(isOn: $settings.largeFont) {
                        Label("settings.appearance.largeFont", systemImage: "textformat.size")
                    }
                }

                // MARK: 游戏辅助
                Section {
                    Toggle(isOn: $settings.mistakeHighlight) {
                        Label("settings.game.mistakeHighlight", systemImage: "exclamationmark.triangle")
                    }
                    Toggle(isOn: $settings.highlightPeers) {
                        Label("settings.game.highlightPeers", systemImage: "square.grid.3x3.middle.filled")
                    }
                    Toggle(isOn: $settings.autoNotesRemoval) {
                        Label("settings.game.autoNotes", systemImage: "pencil.slash")
                    }
                    Toggle(isOn: $settings.hapticsEnabled) {
                        Label("settings.game.haptics", systemImage: "iphone.radiowaves.left.and.right")
                    }
                } header: {
                    Text("settings.section.game")
                } footer: {
                    Text("settings.game.footer")
                }

                // MARK: 完整版
                Section("settings.section.purchase") {
                    if store.isUnlocked {
                        Label("settings.purchase.unlocked", systemImage: "checkmark.seal.fill")
                            .foregroundStyle(.green)
                    } else {
                        Button {
                            showPaywall = true
                        } label: {
                            Label("settings.purchase.unlock", systemImage: "crown.fill")
                        }
                    }
                    Button {
                        Task { await store.restore() }
                    } label: {
                        Label("settings.purchase.restore", systemImage: "arrow.clockwise")
                    }
                }

                // MARK: 关于
                Section("settings.section.about") {
                    LabeledContent {
                        Text(appVersion)
                    } label: {
                        Label("settings.about.version", systemImage: "info.circle")
                    }
                    Link(destination: URL(string: "https://www.apple.com/legal/privacy/")!) {
                        Label("settings.about.privacy", systemImage: "hand.raised")
                    }
                    Link(destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!) {
                        Label("settings.about.terms", systemImage: "doc.text")
                    }
                }
            }
            .navigationTitle(Text("tab.settings"))
            .sheet(isPresented: $showPaywall) { PaywallView() }
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
        .environment(SettingsStore())
        .environment(PurchaseManager())
}
