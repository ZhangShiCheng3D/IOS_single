//
//  PaywallView.swift
//  DocScanPro
//
//  专业版付费墙。强调隐私卖点与一次性买断（无订阅）。
//

import SwiftUI
import StoreKit

struct PaywallView: View {

    @EnvironmentObject private var purchaseManager: PurchaseManager
    @Environment(\.dismiss) private var dismiss

    @State private var isPurchasing = false
    @State private var showRestoreResult = false
    @State private var isShowingPrivacy = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    header
                    featureList
                    purchaseSection
                    legalLinks
                }
                .padding(24)
            }
            .background(backgroundGradient.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                            .font(.title3)
                    }
                    .accessibilityLabel(Text("common.close"))
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("paywall.restore") {
                        Task {
                            await purchaseManager.restorePurchases()
                            showRestoreResult = true
                        }
                    }
                    .font(.subheadline)
                }
            }
            .alert("paywall.restore.title", isPresented: $showRestoreResult) {
                Button("common.ok", role: .cancel) {
                    if purchaseManager.isPro { dismiss() }
                }
            } message: {
                // 用 if/else 而非三元，确保命中 LocalizedStringKey 初始化器（三元字面量会退化为不本地化的 String）。
                if purchaseManager.isPro {
                    Text("paywall.restore.success")
                } else {
                    Text("paywall.restore.none")
                }
            }
            .onChange(of: purchaseManager.isPro) { _, isPro in
                if isPro {
                    Haptics.success()
                    dismiss()
                }
            }
            .alert(
                "common.error",
                isPresented: Binding(
                    get: { purchaseManager.lastErrorMessage != nil },
                    set: { if !$0 { purchaseManager.lastErrorMessage = nil } }
                )
            ) {
                Button("common.ok", role: .cancel) {}
            } message: {
                Text(purchaseManager.lastErrorMessage ?? "")
            }
            .sheet(isPresented: $isShowingPrivacy) {
                NavigationStack { PrivacyView() }
            }
        }
    }

    // MARK: - Sections

    private var header: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.15))
                    .frame(width: 96, height: 96)
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
            }
            .padding(.top, 12)
            .accessibilityHidden(true)

            Text("paywall.title")
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)

            Text("paywall.subtitle")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var featureList: some View {
        VStack(alignment: .leading, spacing: 18) {
            PaywallFeatureRow(
                icon: "text.viewfinder",
                titleKey: "paywall.feature.ocr.title",
                subtitleKey: "paywall.feature.ocr.subtitle"
            )
            PaywallFeatureRow(
                icon: "square.stack.3d.up.fill",
                titleKey: "paywall.feature.batch.title",
                subtitleKey: "paywall.feature.batch.subtitle"
            )
            PaywallFeatureRow(
                icon: "folder.fill.badge.plus",
                titleKey: "paywall.feature.organize.title",
                subtitleKey: "paywall.feature.organize.subtitle"
            )
            PaywallFeatureRow(
                icon: "wifi.slash",
                titleKey: "paywall.feature.privacy.title",
                subtitleKey: "paywall.feature.privacy.subtitle"
            )
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var purchaseSection: some View {
        VStack(spacing: 12) {
            if let product = purchaseManager.proProduct {
                Button {
                    Task { await buy(product) }
                } label: {
                    HStack {
                        if isPurchasing {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text(String(format: NSLocalizedString("paywall.buy.cta", comment: ""), product.displayPrice))
                                .font(.headline)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(isPurchasing)

                Text("paywall.oneTime.note")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else if purchaseManager.isLoading {
                ProgressView().padding()
            } else {
                Text("paywall.unavailable")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var legalLinks: some View {
        HStack(spacing: 18) {
            Link("paywall.terms", destination: AppLinks.termsOfUse)
            // 隐私政策在 App 内原生呈现，无需外部网站。
            Button("paywall.privacy") { isShowingPrivacy = true }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }

    private var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [Color.accentColor.opacity(0.10), Color(.systemBackground)],
            startPoint: .top,
            endPoint: .center
        )
    }

    // MARK: - Actions

    private func buy(_ product: Product) async {
        isPurchasing = true
        defer { isPurchasing = false }
        await purchaseManager.purchase(product)
    }
}

/// 付费墙单条功能行。
private struct PaywallFeatureRow: View {
    let icon: String
    let titleKey: LocalizedStringKey
    let subtitleKey: LocalizedStringKey

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(Color.accentColor)
                .frame(width: 32)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(titleKey)
                    .font(.headline)
                Text(subtitleKey)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    PaywallView()
        .environmentObject(PurchaseManager.shared)
}
