//
//  PaywallView.swift
//  PaperGames
//
//  付费墙界面。展示完整版权益、价格，提供购买与恢复购买入口。
//

import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(PurchaseManager.self) private var store
    @Environment(\.dismiss) private var dismiss

    /// 卖点列表。
    private let benefits: [(symbol: String, titleKey: LocalizedStringKey, descKey: LocalizedStringKey)] = [
        ("infinity", "paywall.benefit.unlimited.title", "paywall.benefit.unlimited.desc"),
        ("flame.fill", "paywall.benefit.difficulty.title", "paywall.benefit.difficulty.desc"),
        ("square.grid.2x2.fill", "paywall.benefit.games.title", "paywall.benefit.games.desc"),
        ("nosign", "paywall.benefit.noads.title", "paywall.benefit.noads.desc")
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    header
                    benefitList
                    purchaseSection
                    restoreButton
                    legalText
                }
                .padding(24)
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle(Text("paywall.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityLabel(Text("common.close"))
                }
            }
            .alert(
                Text("common.error"),
                isPresented: Binding(
                    get: { store.errorMessage != nil },
                    set: { if !$0 { store.errorMessage = nil } }
                )
            ) {
                Button("common.ok", role: .cancel) { store.errorMessage = nil }
            } message: {
                Text(store.errorMessage ?? "")
            }
        }
    }

    // MARK: - 子视图

    private var header: some View {
        VStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.appAccent.gradient)
                    .frame(width: 96, height: 96)
                    .shadow(color: .appAccent.opacity(0.4), radius: 16, y: 8)
                Image(systemName: "lock.open.fill")
                    .font(.system(size: 44, weight: .bold))
                    .foregroundStyle(.white)
            }
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

    private var benefitList: some View {
        VStack(spacing: 16) {
            ForEach(benefits, id: \.symbol) { benefit in
                HStack(spacing: 16) {
                    Image(systemName: benefit.symbol)
                        .font(.title3)
                        .foregroundStyle(Color.appAccent)
                        .frame(width: 36, height: 36)
                        .background(Color.appAccent.opacity(0.12), in: Circle())
                    VStack(alignment: .leading, spacing: 2) {
                        Text(benefit.titleKey)
                            .font(.headline)
                        Text(benefit.descKey)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
            }
        }
        .padding(AppMetrics.cardPadding)
        .background(Color.appSurface, in: RoundedRectangle(cornerRadius: AppMetrics.cornerRadius, style: .continuous))
    }

    @ViewBuilder
    private var purchaseSection: some View {
        if store.isUnlocked {
            Label("paywall.unlocked", systemImage: "checkmark.seal.fill")
                .font(.headline)
                .foregroundStyle(.green)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green.opacity(0.12), in: RoundedRectangle(cornerRadius: AppMetrics.cornerRadius))
        } else if let product = store.unlockProduct {
            Button {
                Task { await purchase(product) }
            } label: {
                HStack {
                    if store.isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Text("paywall.buy.\(product.displayPrice)")
                            .font(.headline)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .foregroundStyle(.white)
                .background(Color.appAccent.gradient, in: RoundedRectangle(cornerRadius: AppMetrics.cornerRadius, style: .continuous))
            }
            .disabled(store.isLoading)
        } else {
            // 商品尚未加载（如无网络）。
            VStack(spacing: 8) {
                ProgressView()
                Text("paywall.loading")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
        }
    }

    private var restoreButton: some View {
        Button {
            Task { await store.restore() }
        } label: {
            Text("paywall.restore")
                .font(.subheadline)
        }
        .disabled(store.isLoading)
    }

    private var legalText: some View {
        Text("paywall.legal")
            .font(.caption2)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal)
    }

    private func purchase(_ product: Product) async {
        let success = await store.purchase(product)
        if success { dismiss() }
    }
}

#Preview {
    PaywallView()
        .environment(PurchaseManager())
}
