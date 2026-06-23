//
//  PaywallView.swift
//  LumenPuzzle
//
//  付费墙（StoreKit 2）。一次性买断解锁全部关卡与内容。
//  设计语气与产品一致：诚恳、克制、强调"一次购买，永久无打扰"。
//

import SwiftUI

struct PaywallView: View {

    @EnvironmentObject private var purchaseManager: PurchaseManager
    @Environment(\.dismiss) private var dismiss

    @State private var glow = false
    @State private var showPrivacy = false

    /// Apple 标准 EULA（使用条款）链接。
    private let termsURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!

    var body: some View {
        ZStack {
            LinearGradient.lumenBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    closeButton
                    hero
                    benefits
                    purchaseControls
                    legal
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 32)
            }
        }
        .onAppear { glow = true }
        .alert(
            "store.error.title",
            isPresented: Binding(
                get: { purchaseManager.errorMessage != nil },
                set: { if !$0 { purchaseManager.errorMessage = nil } }
            )
        ) {
            Button("common.ok", role: .cancel) {}
        } message: {
            Text(purchaseManager.errorMessage ?? "")
        }
    }

    // MARK: - 区块

    private var closeButton: some View {
        HStack {
            Spacer()
            Button {
                Haptics.selection()
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.headline)
                    .foregroundStyle(Color.lumenTextSecondary)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Color.lumenSurface.opacity(0.5)))
            }
            .accessibilityLabel(Text("a11y.close"))
        }
        .padding(.top, 12)
    }

    private var hero: some View {
        VStack(spacing: 14) {
            Image(systemName: "sun.max.fill")
                .font(.system(size: 64, weight: .light))
                .foregroundStyle(Color.lumenAccent)
                .shadow(color: Color.lumenAccent.opacity(0.7), radius: 26)
                .scaleEffect(glow ? 1.06 : 0.96)
                .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: glow)
                .accessibilityHidden(true)

            Text("paywall.title")
                .font(.title.weight(.semibold))
                .foregroundStyle(Color.lumenText)
                .multilineTextAlignment(.center)

            Text("paywall.subtitle")
                .font(.subheadline)
                .foregroundStyle(Color.lumenTextSecondary)
                .multilineTextAlignment(.center)
        }
    }

    private var benefits: some View {
        VStack(alignment: .leading, spacing: 16) {
            benefitRow(icon: "lock.open.fill", titleKey: "paywall.benefit.levels", detailKey: "paywall.benefit.levels.detail")
            benefitRow(icon: "nosign", titleKey: "paywall.benefit.noads", detailKey: "paywall.benefit.noads.detail")
            benefitRow(icon: "infinity", titleKey: "paywall.benefit.forever", detailKey: "paywall.benefit.forever.detail")
            benefitRow(icon: "rosette", titleKey: "paywall.benefit.achievements", detailKey: "paywall.benefit.achievements.detail")
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.lumenSurface.opacity(0.4))
        )
    }

    private func benefitRow(icon: String, titleKey: LocalizedStringKey, detailKey: LocalizedStringKey) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color.lumenAccent)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 3) {
                Text(titleKey)
                    .font(.headline)
                    .foregroundStyle(Color.lumenText)
                Text(detailKey)
                    .font(.caption)
                    .foregroundStyle(Color.lumenTextSecondary)
            }
        }
    }

    @ViewBuilder
    private var purchaseControls: some View {
        VStack(spacing: 14) {
            Button {
                Haptics.selection()
                Task {
                    let success = await purchaseManager.purchase()
                    if success { dismiss() }
                }
            } label: {
                ZStack {
                    if purchaseManager.isProcessing {
                        ProgressView()
                            .tint(.black)
                    } else {
                        HStack(spacing: 8) {
                            Text("paywall.buy")
                                .font(.headline)
                            if let price = purchaseManager.displayPrice {
                                Text(price)
                                    .font(.headline.weight(.bold))
                            }
                        }
                    }
                }
                .foregroundStyle(Color.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color.lumenAccent))
                .lumenAccentShadow()
            }
            .disabled(purchaseManager.isProcessing)

            Button {
                Haptics.selection()
                Task {
                    await purchaseManager.restore()
                    if purchaseManager.isUnlocked { dismiss() }
                }
            } label: {
                Text("paywall.restore")
                    .font(.subheadline)
                    .foregroundStyle(Color.lumenTextSecondary)
            }
            .disabled(purchaseManager.isProcessing)
        }
    }

    private var legal: some View {
        VStack(spacing: Spacing.sm) {
            Text("paywall.legal")
                .font(.caption2)
                .foregroundStyle(Color.lumenTextSecondary.opacity(0.7))
                .multilineTextAlignment(.center)

            HStack(spacing: Spacing.lg) {
                Link("settings.terms", destination: termsURL)
                Button("settings.privacy") {
                    Haptics.selection()
                    showPrivacy = true
                }
            }
            .font(.caption2.weight(.medium))
            .foregroundStyle(Color.lumenTextSecondary)
        }
        .sheet(isPresented: $showPrivacy) {
            NavigationStack {
                PrivacyPolicyView(presentedAsSheet: true)
            }
        }
    }
}

#Preview {
    PaywallView()
        .environmentObject(PurchaseManager())
}
