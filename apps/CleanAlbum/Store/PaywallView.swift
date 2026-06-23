//
//  PaywallView.swift
//  CleanAlbum
//
//  付费墙：解锁批量清理。强调隐私 + 一次买断、终身使用。
//

import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(PurchaseManager.self) private var purchase
    @Environment(\.dismiss) private var dismiss

    /// 解锁成功回调。
    var onUnlocked: (() -> Void)?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    header
                    featureList
                    privacyBadge
                    purchaseButton
                    restoreButton
                    legalFooter
                }
                .padding(24)
            }
            .background(Color.appBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                            .font(.title3)
                    }
                    .accessibilityLabel(Text("action.close"))
                }
            }
        }
    }

    // MARK: - 子视图

    private var header: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [.brand.opacity(0.25), .brand.opacity(0.05)],
                        startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 96, height: 96)
                Image(systemName: "sparkles")
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(Color.brand)
            }
            .padding(.top, 8)

            Text("paywall.title")
                .font(.title.bold())
                .multilineTextAlignment(.center)

            Text("paywall.subtitle")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var featureList: some View {
        VStack(alignment: .leading, spacing: 16) {
            PaywallFeatureRow(icon: "checkmark.seal.fill", titleKey: "paywall.feature.batch")
            PaywallFeatureRow(icon: "trash.fill", titleKey: "paywall.feature.oneTap")
            PaywallFeatureRow(icon: "infinity", titleKey: "paywall.feature.lifetime")
            PaywallFeatureRow(icon: "lock.shield.fill", titleKey: "paywall.feature.privacy")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface()
    }

    private var privacyBadge: some View {
        Label("paywall.privacy.badge", systemImage: "iphone.gen3")
            .font(.footnote.weight(.medium))
            .foregroundStyle(Color.brand)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color.brand.opacity(0.12))
            .clipShape(Capsule())
    }

    private var purchaseButton: some View {
        Button {
            Task {
                guard let product = purchase.products.first(where: { $0.id == ProductID.proUnlock }) else { return }
                let ok = await purchase.purchase(product)
                if ok {
                    Haptics.success()
                    onUnlocked?()
                    dismiss()
                } else if purchase.lastError != nil {
                    Haptics.error()
                }
            }
        } label: {
            VStack(spacing: 4) {
                Text("paywall.cta")
                    .font(.headline)
                Text(verbatim: purchase.proPriceText)
                    .font(.subheadline.weight(.semibold))
                    .opacity(0.9)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .foregroundStyle(.white)
            .background(
                LinearGradient(colors: [.brand, .brand.opacity(0.8)],
                               startPoint: .leading, endPoint: .trailing)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .disabled(purchase.isLoading)
        .overlay {
            if purchase.isLoading {
                ProgressView().tint(.white)
            }
        }
    }

    private var restoreButton: some View {
        Button {
            Task {
                await purchase.restore()
                if purchase.isPro {
                    onUnlocked?()
                    dismiss()
                }
            }
        } label: {
            Text("paywall.restore")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var legalFooter: some View {
        Text("paywall.legal")
            .font(.caption2)
            .foregroundStyle(.tertiary)
            .multilineTextAlignment(.center)
            .padding(.top, 4)
    }
}

/// 付费墙功能行。
private struct PaywallFeatureRow: View {
    let icon: String
    let titleKey: LocalizedStringKey

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color.brand)
                .frame(width: 28)
            Text(titleKey)
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
    }
}

#Preview {
    PaywallView()
        .environment(PurchaseManager())
}
