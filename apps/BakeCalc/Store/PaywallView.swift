//
//  PaywallView.swift
//  BakeCalc
//
//  付费墙。展示专业版价值点、价格、购买与恢复按钮。
//  买断制：一次购买，永久解锁。
//

import SwiftUI
import StoreKit

struct PaywallView: View {
    @EnvironmentObject private var purchaseManager: PurchaseManager
    @Environment(\.dismiss) private var dismiss

    /// 专业版功能卖点。
    private let benefits: [(icon: String, titleKey: String, subtitleKey: String)] = [
        ("scalemass",            "paywall.benefit.scale.title",   "paywall.benefit.scale.sub"),
        ("list.bullet.rectangle","paywall.benefit.density.title", "paywall.benefit.density.sub"),
        ("square.and.arrow.down","paywall.benefit.save.title",    "paywall.benefit.save.sub"),
        ("circle.grid.cross",    "paywall.benefit.pan.title",     "paywall.benefit.pan.sub"),
        ("oval.portrait",        "paywall.benefit.egg.title",     "paywall.benefit.egg.sub")
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    header
                    benefitsList
                    purchaseSection
                    legalLinks
                }
                .padding()
            }
            .background(Color.bcBackground.ignoresSafeArea())
            .navigationTitle(Text("paywall.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                            .accessibilityLabel(Text("common.close"))
                    }
                }
            }
            .alert(
                Text("common.notice"),
                isPresented: Binding(
                    get: { purchaseManager.lastError != nil },
                    set: { if !$0 { purchaseManager.lastError = nil } }
                )
            ) {
                Button("common.ok", role: .cancel) { purchaseManager.lastError = nil }
            } message: {
                Text(purchaseManager.lastError ?? "")
            }
            .onChange(of: purchaseManager.isPro) { _, isPro in
                if isPro {
                    Haptics.success()
                    dismiss()
                }
            }
        }
    }

    // MARK: - 子视图

    private var header: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.bcAccent, Color.bcSecondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 88, height: 88)
                Image(systemName: "crown.fill")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(.white)
            }
            .shadow(color: Color.bcAccent.opacity(0.35), radius: 12, y: 6)

            Text("paywall.headline")
                .font(.title2.bold())
                .multilineTextAlignment(.center)

            Text("paywall.subheadline")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
    }

    private var benefitsList: some View {
        VStack(spacing: 14) {
            ForEach(benefits, id: \.titleKey) { benefit in
                HStack(spacing: 14) {
                    Image(systemName: benefit.icon)
                        .font(.title3)
                        .foregroundStyle(Color.bcAccent)
                        .frame(width: 32)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(LocalizedStringKey(benefit.titleKey))
                            .font(.subheadline.weight(.semibold))
                        Text(LocalizedStringKey(benefit.subtitleKey))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
            }
        }
        .bcCard()
    }

    private var purchaseSection: some View {
        VStack(spacing: 12) {
            Button {
                Haptics.tap()
                Task { await purchaseManager.purchasePro() }
            } label: {
                HStack {
                    if purchaseManager.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("paywall.buy")
                            .fontWeight(.semibold)
                        Text(purchaseManager.proPriceText)
                            .fontWeight(.bold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [Color.bcAccent, Color.bcSecondary],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .disabled(purchaseManager.isLoading)

            Text("paywall.onetime")
                .font(.caption)
                .foregroundStyle(.secondary)

            Button {
                Task { await purchaseManager.restorePurchases() }
            } label: {
                Text("paywall.restore")
                    .font(.subheadline)
            }
            .disabled(purchaseManager.isLoading)
        }
    }

    private var legalLinks: some View {
        VStack(spacing: 4) {
            Text("paywall.legal")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .padding(.bottom, 8)
    }
}

#Preview("付费墙") {
    PaywallView()
        .environmentObject(PurchaseManager())
}
