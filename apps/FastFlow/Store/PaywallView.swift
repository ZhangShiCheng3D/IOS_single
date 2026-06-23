//
//  PaywallView.swift
//  FastFlow
//
//  高级解锁付费墙。展示功能权益、价格、购买与恢复购买。
//

import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(PurchaseManager.self) private var purchaseManager
    @Environment(\.dismiss) private var dismiss

    /// 权益列表。
    private let benefits: [(icon: String, titleKey: String, descKey: String)] = [
        ("chart.xyaxis.line", "paywall.benefit.charts.title", "paywall.benefit.charts.desc"),
        ("slider.horizontal.3", "paywall.benefit.custom.title", "paywall.benefit.custom.desc"),
        ("square.stack.3d.up", "paywall.benefit.widget.title", "paywall.benefit.widget.desc"),
        ("heart.text.square", "paywall.benefit.health.title", "paywall.benefit.health.desc")
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    header
                    benefitList
                    purchaseSection
                    footnote
                }
                .padding(24)
            }
            .background(backgroundGradient.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                            .font(.title2)
                    }
                    .accessibilityLabel(Text("common.close"))
                }
            }
            .alert(
                NSLocalizedString("common.notice", comment: ""),
                isPresented: errorBinding
            ) {
                Button("common.ok", role: .cancel) {}
            } message: {
                Text(purchaseManager.lastErrorMessage ?? "")
            }
        }
    }

    // MARK: - 子视图

    private var header: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.15))
                    .frame(width: 96, height: 96)
                Image(systemName: "sparkles")
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
            }
            Text("paywall.title")
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
            Text("paywall.subtitle")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
    }

    private var benefitList: some View {
        VStack(spacing: 16) {
            ForEach(benefits, id: \.titleKey) { benefit in
                HStack(spacing: 16) {
                    Image(systemName: benefit.icon)
                        .font(.title2)
                        .foregroundStyle(Color.accentColor)
                        .frame(width: 40, height: 40)
                        .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(LocalizedStringKey(benefit.titleKey))
                            .font(.headline)
                        Text(LocalizedStringKey(benefit.descKey))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 0)
                }
            }
        }
        .padding(DS.Spacing.lg - 4)
        .cardStyle(cornerRadius: DS.Radius.lg)
    }

    private var purchaseSection: some View {
        VStack(spacing: 12) {
            if purchaseManager.isPremiumUnlocked {
                Label("paywall.unlocked", systemImage: "checkmark.seal.fill")
                    .font(.headline)
                    .foregroundStyle(Color.goalReached)
                    .padding()
            } else {
                Button {
                    Task {
                        let ok = await purchaseManager.purchasePremium()
                        if ok { dismiss() }
                    }
                } label: {
                    HStack {
                        if purchaseManager.isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text(String(
                                format: NSLocalizedString("paywall.buy.format", comment: ""),
                                purchaseManager.premiumDisplayPrice
                            ))
                            .font(.headline)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(purchaseManager.isLoading)

                Button {
                    Task { await purchaseManager.restorePurchases() }
                } label: {
                    Text("paywall.restore")
                        .font(.subheadline)
                }
                .disabled(purchaseManager.isLoading)
            }
        }
    }

    private var footnote: some View {
        Text("paywall.footnote")
            .font(.caption2)
            .foregroundStyle(.tertiary)
            .multilineTextAlignment(.center)
            .padding(.horizontal)
    }

    private var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [Color.accentColor.opacity(0.10), Color(.systemBackground)],
            startPoint: .top,
            endPoint: .center
        )
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { purchaseManager.lastErrorMessage != nil },
            set: { if !$0 { purchaseManager.lastErrorMessage = nil } }
        )
    }
}

#Preview {
    PaywallView()
        .environment(PurchaseManager())
}
