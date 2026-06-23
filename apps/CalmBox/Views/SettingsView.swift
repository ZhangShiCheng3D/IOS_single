//
//  SettingsView.swift
//  CalmBox
//
//  设置页：触觉开关、解锁/恢复购买、冥想统计、关于与法律链接。
//

import SwiftUI
import SwiftData

struct SettingsView: View {

    @Environment(HapticManager.self) private var haptics
    @Environment(PurchaseManager.self) private var purchaseManager
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \MeditationSession.startedAt, order: .reverse) private var sessions: [MeditationSession]

    @AppStorage(AppConstants.DefaultsKey.hapticsEnabled) private var hapticsEnabled = true
    @State private var showPaywall = false

    /// 恢复购买结果提示。仅在用户从设置页主动发起恢复时弹出。
    @State private var didRequestRestore = false
    @State private var restoreMessage: String?

    /// 累计冥想分钟数。
    private var totalMeditationMinutes: Int {
        Int(sessions.reduce(0) { $0 + $1.completedDuration } / 60)
    }

    private var completedSessions: Int {
        sessions.filter { $0.isCompleted }.count
    }

    var body: some View {
        NavigationStack {
            Form {
                // 解锁状态
                Section {
                    if purchaseManager.hasUnlockedAll {
                        HStack {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundStyle(.green)
                            Text("settings.unlocked")
                            Spacer()
                        }
                    } else {
                        Button {
                            showPaywall = true
                        } label: {
                            Label("settings.unlockAll", systemImage: "lock.open.fill")
                        }
                    }
                    Button {
                        didRequestRestore = true
                        Task { await purchaseManager.restore() }
                    } label: {
                        Label("settings.restore", systemImage: "arrow.clockwise")
                    }
                } header: {
                    Text("settings.purchase")
                }

                // 偏好
                Section {
                    Toggle(isOn: $hapticsEnabled) {
                        Label("settings.haptics", systemImage: "iphone.radiowaves.left.and.right")
                    }
                    .onChange(of: hapticsEnabled) { _, newValue in
                        haptics.isEnabled = newValue
                    }
                } header: {
                    Text("settings.preferences")
                } footer: {
                    Text("settings.haptics.footer")
                }

                // 冥想统计
                Section {
                    LabeledContent("settings.totalMinutes", value: "\(totalMeditationMinutes)")
                    LabeledContent("settings.completedSessions", value: "\(completedSessions)")
                } header: {
                    Text("settings.stats")
                }

                // 关于
                Section {
                    Link(destination: URL(string: AppConstants.Links.privacyPolicy)!) {
                        Label("settings.privacy", systemImage: "hand.raised.fill")
                    }
                    Link(destination: URL(string: AppConstants.Links.terms)!) {
                        Label("settings.terms", systemImage: "doc.text.fill")
                    }
                    Link(destination: URL(string: AppConstants.Links.support)!) {
                        Label("settings.support", systemImage: "questionmark.circle.fill")
                    }
                    LabeledContent("settings.version", value: appVersion)
                } header: {
                    Text("settings.about")
                }
            }
            .navigationTitle("settings.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("common.done") { dismiss() }
                }
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .onChange(of: purchaseManager.state) { _, newState in
                // 仅响应由本页发起的恢复操作，避免与付费墙状态相互干扰。
                guard didRequestRestore else { return }
                switch newState {
                case .success:
                    didRequestRestore = false
                    restoreMessage = String(localized: "settings.unlocked")
                    purchaseManager.resetState()
                case .failed(let message):
                    didRequestRestore = false
                    restoreMessage = message
                    purchaseManager.resetState()
                default:
                    break
                }
            }
            .alert("settings.restore", isPresented: Binding(
                get: { restoreMessage != nil },
                set: { if !$0 { restoreMessage = nil } }
            )) {
                Button("common.done", role: .cancel) { restoreMessage = nil }
            } message: {
                if let restoreMessage { Text(restoreMessage) }
            }
            .onAppear {
                haptics.isEnabled = hapticsEnabled
            }
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
        .environment(HapticManager())
        .environment(PurchaseManager())
        .modelContainer(for: [MeditationSession.self], inMemory: true)
}
