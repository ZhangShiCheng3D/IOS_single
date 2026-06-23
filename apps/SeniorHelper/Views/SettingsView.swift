//
//  SettingsView.swift
//  SeniorHelper
//
//  设置：字号引导、语音开关、通知状态、购买/恢复、关于。
//

import SwiftUI
import UIKit

struct SettingsView: View {
    @Environment(PurchaseManager.self) private var purchaseManager
    @Environment(SpeechManager.self) private var speechManager

    @State private var notificationManager = NotificationManager()
    @State private var showPaywall = false

    var body: some View {
        // 使用本地绑定驱动 @Observable 的语音开关。
        @Bindable var speech = speechManager

        Form {
            purchaseSection

            Section {
                Toggle(isOn: $speech.isVoiceEnabled) {
                    Label("语音播报", systemImage: "speaker.wave.3.fill")
                        .font(.body.weight(.medium))
                }
                .tint(Theme.success)
                .onChange(of: speech.isVoiceEnabled) { _, on in
                    if on { speechManager.speak(String(localized: "语音播报已开启"), force: true) }
                }
            } header: {
                Text("语音")
            } footer: {
                Text("开启后，操作时会有语音提示，方便看不清屏幕时使用。")
            }

            fontSection
            notificationSection
            siriSection
            aboutSection
        }
        .background(Theme.pageBackground)
        .navigationTitle(Text("设置"))
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .task {
            await notificationManager.refreshStatus()
        }
    }

    // MARK: - 购买

    @ViewBuilder
    private var purchaseSection: some View {
        Section {
            if purchaseManager.isUnlocked {
                HStack(spacing: Theme.padding) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.largeTitle)
                        .foregroundStyle(Theme.success)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("已解锁完整版")
                            .font(.title3.weight(.bold))
                        Text("感谢您的支持，全部功能已开启")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 6)
            } else {
                Button {
                    showPaywall = true
                } label: {
                    HStack(spacing: Theme.padding) {
                        Image(systemName: "lock.open.fill")
                            .font(.largeTitle)
                            .foregroundStyle(Theme.accent)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("解锁完整版")
                                .font(.title3.weight(.bold))
                                .foregroundStyle(.primary)
                            Text("一次购买，永久使用全部功能")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 6)
                }
                .buttonStyle(.plain)

                Button {
                    Task { await purchaseManager.restore() }
                } label: {
                    Text("恢复购买")
                        .font(.body.weight(.medium))
                }
            }
        }
    }

    // MARK: - 字号

    private var fontSection: some View {
        Section {
            VStack(alignment: .leading, spacing: Theme.smallPadding) {
                Text("示例文字")
                    .font(.body)
                Text("当前字号会随系统设置自动变大或变小。")
                    .font(.body)
                    .foregroundStyle(.secondary)
                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Label("在系统设置中调整字号", systemImage: "textformat.size")
                        .font(.body.weight(.semibold))
                }
                .padding(.top, 4)
            }
            .padding(.vertical, 4)
        } header: {
            Text("字号")
        } footer: {
            Text("本应用已适配超大字号。前往「设置 › 辅助功能 › 显示与文字大小」可进一步放大。")
        }
    }

    // MARK: - 通知

    private var notificationSection: some View {
        Section {
            HStack {
                Label("用药提醒通知", systemImage: "bell.fill")
                    .font(.body.weight(.medium))
                Spacer()
                Text(notificationStatusText)
                    .font(.body)
                    .foregroundStyle(notificationAuthorized ? Theme.success : Theme.danger)
            }
            if !notificationAuthorized {
                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Text("前往设置开启通知")
                        .font(.body.weight(.semibold))
                }
            }
        } header: {
            Text("通知")
        }
    }

    private var notificationAuthorized: Bool {
        switch notificationManager.authorizationStatus {
        case .authorized, .provisional, .ephemeral: return true
        default: return false
        }
    }

    private var notificationStatusText: LocalizedStringKey {
        notificationAuthorized ? "已开启" : "未开启"
    }

    // MARK: - Siri

    private var siriSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 6) {
                Label("用 Siri 打开放大镜", systemImage: "mic.fill")
                    .font(.body.weight(.medium))
                Text("对 Siri 说「打开放大镜」即可快速使用。首次使用请按提示授权。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
        } header: {
            Text("Siri 快捷指令")
        }
    }

    // MARK: - 关于

    private var aboutSection: some View {
        Section {
            HStack {
                Text("版本")
                    .font(.body)
                Spacer()
                Text(verbatim: appVersion)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            NavigationLink {
                PrivacyPolicyView()
            } label: {
                Text("隐私政策")
            }
            Link(destination: URL(string: "mailto:support@seniorhelper.app")!) {
                Text("联系与帮助")
            }
        } header: {
            Text("关于")
        } footer: {
            Text("SeniorHelper · 让长辈生活更便利\n所有数据仅保存在本机，不上传云端。")
        }
    }

    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
    .environment(PurchaseManager())
    .environment(SpeechManager())
}
