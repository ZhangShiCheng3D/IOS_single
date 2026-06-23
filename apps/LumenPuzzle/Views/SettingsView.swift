//
//  SettingsView.swift
//  LumenPuzzle
//
//  设置。包含购买状态、恢复购买、关于信息。
//  本作无广告、无第三方追踪，设置极简。
//

import SwiftUI
import SwiftData

struct SettingsView: View {

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var purchaseManager: PurchaseManager

    @State private var showPaywall = false
    @State private var completedCount = 0
    /// 恢复购买的结果提示。
    @State private var restoreResultMessage: String?

    /// Apple 标准 EULA（使用条款）链接。
    private let termsURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!

    var body: some View {
        ZStack {
            LinearGradient.lumenBackground.ignoresSafeArea()

            List {
                purchaseSection
                progressSection
                legalSection
                aboutSection
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle(Text("settings.title"))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            completedCount = ProgressService(context: modelContext).completedCount()
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView().environmentObject(purchaseManager)
        }
        .alert(
            "settings.restore.result.title",
            isPresented: Binding(
                get: { restoreResultMessage != nil },
                set: { if !$0 { restoreResultMessage = nil } }
            )
        ) {
            Button("common.ok", role: .cancel) {}
        } message: {
            Text(restoreResultMessage ?? "")
        }
    }

    // MARK: - 分区

    private var purchaseSection: some View {
        Section {
            if purchaseManager.isUnlocked {
                HStack {
                    Label("settings.purchased", systemImage: "checkmark.seal.fill")
                        .foregroundStyle(Color.lumenAccent)
                    Spacer()
                }
            } else {
                Button {
                    Haptics.selection()
                    showPaywall = true
                } label: {
                    Label("settings.unlock", systemImage: "cart.fill")
                }
                .foregroundStyle(Color.lumenAccent)
            }

            Button {
                Haptics.selection()
                Task {
                    await purchaseManager.restore()
                    if let error = purchaseManager.errorMessage {
                        restoreResultMessage = error
                        purchaseManager.errorMessage = nil
                    } else if purchaseManager.isUnlocked {
                        restoreResultMessage = "settings.restore.success".localized
                    } else {
                        restoreResultMessage = "settings.restore.empty".localized
                    }
                }
            } label: {
                Label("settings.restore", systemImage: "arrow.clockwise")
            }
            .foregroundStyle(Color.lumenText)
            .disabled(purchaseManager.isProcessing)
        } header: {
            Text("settings.section.purchase")
        } footer: {
            Text("settings.purchase.footer")
        }
        .listRowBackground(Color.lumenSurface.opacity(0.4))
    }

    private var legalSection: some View {
        Section {
            NavigationLink {
                PrivacyPolicyView()
            } label: {
                Label("settings.privacy", systemImage: "hand.raised")
            }

            Link(destination: termsURL) {
                Label("settings.terms", systemImage: "doc.text")
            }
        } header: {
            Text("settings.section.legal")
        }
        .listRowBackground(Color.lumenSurface.opacity(0.4))
        .foregroundStyle(Color.lumenText)
    }

    private var progressSection: some View {
        Section {
            HStack {
                Text("settings.completed")
                Spacer()
                Text("\(completedCount)/\(LevelCatalog.count)")
                    .foregroundStyle(Color.lumenTextSecondary)
                    .monospacedDigit()
            }
        } header: {
            Text("settings.section.progress")
        }
        .listRowBackground(Color.lumenSurface.opacity(0.4))
        .foregroundStyle(Color.lumenText)
    }

    private var aboutSection: some View {
        Section {
            HStack {
                Text("settings.version")
                Spacer()
                Text(appVersion)
                    .foregroundStyle(Color.lumenTextSecondary)
            }
            Label("settings.noads", systemImage: "hand.thumbsup")
                .foregroundStyle(Color.lumenTextSecondary)
        } header: {
            Text("settings.section.about")
        } footer: {
            Text("settings.about.footer")
        }
        .listRowBackground(Color.lumenSurface.opacity(0.4))
        .foregroundStyle(Color.lumenText)
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environmentObject(PurchaseManager())
            .modelContainer(for: [LevelProgress.self, AchievementRecord.self], inMemory: true)
    }
}
