//
//  PaywallView.swift
//  CalmBox
//
//  内购付费墙。展示解锁权益、价格、购买与恢复按钮。
//

import SwiftUI
import StoreKit

struct PaywallView: View {

    @Environment(PurchaseManager.self) private var purchaseManager
    @Environment(HapticManager.self) private var haptics
    @Environment(\.dismiss) private var dismiss

    /// 解锁权益列表。
    private let benefits: [(icon: String, titleKey: LocalizedStringKey, descKey: LocalizedStringKey)] = [
        ("waveform", "paywall.benefit.sounds.title", "paywall.benefit.sounds.desc"),
        ("lungs.fill", "paywall.benefit.breathing.title", "paywall.benefit.breathing.desc"),
        ("moon.zzz.fill", "paywall.benefit.meditation.title", "paywall.benefit.meditation.desc"),
        ("slider.horizontal.3", "paywall.benefit.mixer.title", "paywall.benefit.mixer.desc")
    ]

    var body: some View {
        ZStack {
            // 渐变背景营造平静氛围。
            LinearGradient(
                colors: Theme.Palette.brandGradient,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    header
                    benefitList
                    purchaseSection
                    footer
                }
                .padding(AppConstants.Design.contentPadding)
                .padding(.top, 40)
            }

            closeButton
        }
        .presentationDragIndicator(.visible)
        .task(id: purchaseManager.state) {
            if case .success = purchaseManager.state {
                haptics.playSuccess()
                // 购买成功后短暂停留再关闭，给予反馈。
                try? await Task.sleep(for: .seconds(0.6))
                dismiss()
            }
        }
        .onDisappear { purchaseManager.resetState() }
    }

    // MARK: - 子视图

    private var header: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 52))
                .foregroundStyle(.white)
                .shadow(color: .white.opacity(0.4), radius: 12)

            Text("paywall.title")
                .font(.largeTitle.bold())
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            Text("paywall.subtitle")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.85))
                .multilineTextAlignment(.center)
        }
    }

    private var benefitList: some View {
        VStack(spacing: 14) {
            ForEach(benefits, id: \.icon) { benefit in
                HStack(spacing: 16) {
                    Image(systemName: benefit.icon)
                        .font(.title2)
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(.white.opacity(0.18), in: Circle())

                    VStack(alignment: .leading, spacing: 3) {
                        Text(benefit.titleKey)
                            .font(.headline)
                            .foregroundStyle(.white)
                        Text(benefit.descKey)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    Spacer()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 18))
            }
        }
    }

    private var purchaseSection: some View {
        VStack(spacing: 14) {
            if purchaseManager.isLoaded {
                purchaseButton
            } else {
                ProgressView()
                    .tint(.white)
                    .frame(height: 56)
            }

            if case .failed(let message) = purchaseManager.state {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.yellow)
                    .multilineTextAlignment(.center)
            }

            if purchaseManager.state == .pending {
                Label("paywall.pending", systemImage: "clock.fill")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
            }

            Button {
                Task { await purchaseManager.restore() }
            } label: {
                Text("paywall.restore")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.9))
            }
        }
    }

    private var purchaseButton: some View {
        Button {
            Task { await purchaseManager.purchase() }
        } label: {
            HStack {
                if purchaseManager.state == .purchasing {
                    ProgressView().tint(Theme.Palette.brandStart)
                } else {
                    Text("paywall.unlock")
                        .fontWeight(.bold)
                    if let product = purchaseManager.unlockProduct {
                        Text(product.displayPrice)
                            .fontWeight(.bold)
                    } else {
                        Text("¥25")
                            .fontWeight(.bold)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .foregroundStyle(Theme.Palette.brandStart)
            .background(.white, in: RoundedRectangle(cornerRadius: 18))
        }
        .disabled(purchaseManager.state == .purchasing || purchaseManager.state == .pending)
    }

    private var footer: some View {
        VStack(spacing: 8) {
            Text("paywall.onetime")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.7))

            HStack(spacing: 16) {
                Link("paywall.terms", destination: URL(string: AppConstants.Links.terms)!)
                Link("paywall.privacy", destination: URL(string: AppConstants.Links.privacyPolicy)!)
            }
            .font(.caption2)
            .foregroundStyle(.white.opacity(0.7))
        }
        .padding(.top, 8)
    }

    private var closeButton: some View {
        VStack {
            HStack {
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.white.opacity(0.7))
                }
                .padding()
                .accessibilityLabel("common.close")
            }
            Spacer()
        }
    }
}

#Preview {
    PaywallView()
        .environment(PurchaseManager())
        .environment(HapticManager())
}
