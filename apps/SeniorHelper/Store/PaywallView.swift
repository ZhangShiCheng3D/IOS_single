//
//  PaywallView.swift
//  SeniorHelper
//
//  付费墙。银发友好：大图标、大字、卖点清晰，强调「一次购买，永久使用」。
//  面向付费决策者（子女）也面向老人本人，因此文案温暖、无套路。
//

import SwiftUI

struct PaywallView: View {
    @Environment(PurchaseManager.self) private var purchaseManager
    @Environment(SpeechManager.self) private var speechManager
    @Environment(\.dismiss) private var dismiss

    /// 卖点列表。
    private let features: [(icon: String, title: LocalizedStringKey, detail: LocalizedStringKey)] = [
        ("pills.fill", "用药提醒", "拍下药盒，按时提醒，再也不怕忘记吃药"),
        ("phone.fill.arrow.up.right", "紧急联系人", "一键拨打家人电话，关键时刻不慌张"),
        ("speaker.wave.3.fill", "语音播报", "看不清也能听得清，操作全程语音陪伴"),
        ("infinity", "永久使用", "一次购买，永久解锁，无月费、无广告")
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.largePadding) {
                    header
                    featureList
                    purchaseSection
                    legalLinks
                }
                .padding(Theme.padding)
            }
            .background(Theme.pageBackground)
            .navigationTitle(Text("解锁完整版"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                            .accessibilityLabel(Text("关闭"))
                    }
                }
            }
            .alert(
                Text("提示"),
                isPresented: Binding(
                    get: { purchaseManager.errorMessage != nil },
                    set: { if !$0 { purchaseManager.errorMessage = nil } }
                )
            ) {
                Button("好的", role: .cancel) { purchaseManager.errorMessage = nil }
            } message: {
                Text(purchaseManager.errorMessage ?? "")
            }
        }
    }

    // MARK: - 子视图

    private var header: some View {
        VStack(spacing: Theme.smallPadding) {
            Image(systemName: "heart.text.square.fill")
                .font(.system(size: 72))
                .foregroundStyle(Theme.accent)
                .accessibilityHidden(true)

            Text("贴心守护，全家安心")
                .font(.largeTitle.weight(.bold))
                .multilineTextAlignment(.center)

            Text("解锁全部功能，让长辈生活更便利")
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, Theme.padding)
    }

    private var featureList: some View {
        VStack(spacing: Theme.padding) {
            ForEach(features, id: \.icon) { feature in
                HStack(spacing: Theme.padding) {
                    Image(systemName: feature.icon)
                        .font(.title)
                        .foregroundStyle(Theme.accent)
                        .frame(width: 50)
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(feature.title)
                            .font(.title3.weight(.bold))
                        Text(feature.detail)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .cardStyle()
    }

    private var purchaseSection: some View {
        VStack(spacing: Theme.smallPadding) {
            Button {
                Task {
                    Haptics.tap()
                    let ok = await purchaseManager.purchase()
                    if ok {
                        Haptics.success()
                        speechManager.speak(String(localized: "购买成功，感谢您的支持"))
                        dismiss()
                    }
                }
            } label: {
                if purchaseManager.isProcessing {
                    ProgressView()
                        .tint(.white)
                } else {
                    VStack(spacing: 2) {
                        Text("立即解锁")
                        Text(verbatim: purchaseManager.displayPrice + " · " + String(localized: "永久"))
                            .font(.subheadline.weight(.medium))
                            .opacity(0.9)
                    }
                }
            }
            .buttonStyle(.seniorPrimary)
            .disabled(purchaseManager.isProcessing || purchaseManager.unlockProduct == nil)

            Button {
                Task {
                    let ok = await purchaseManager.restore()
                    if ok {
                        Haptics.success()
                        dismiss()
                    }
                }
            } label: {
                Text("恢复购买")
            }
            .buttonStyle(.seniorSecondary)
            .disabled(purchaseManager.isProcessing)

            Text("一次性付款，无自动续费")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.top, 4)
        }
    }

    private var legalLinks: some View {
        HStack(spacing: Theme.padding) {
            Link(destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!) {
                Text("使用条款")
                    .font(.footnote)
            }
            NavigationLink {
                PrivacyPolicyView()
            } label: {
                Text("隐私政策")
                    .font(.footnote)
            }
        }
        .foregroundStyle(.secondary)
    }
}

#Preview {
    PaywallView()
        .environment(PurchaseManager())
        .environment(SpeechManager())
}
