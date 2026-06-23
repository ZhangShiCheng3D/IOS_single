//
//  PaywallView.swift
//  CollageKit
//
//  Pro 解锁付费墙。展示权益、价格、购买与恢复入口。
//

import SwiftUI

struct PaywallView: View {
    @EnvironmentObject private var store: PurchaseManager
    @Environment(\.dismiss) private var dismiss

    @State private var isPurchasing = false
    @State private var showPrivacy = false

    /// Apple 标准最终用户许可协议（EULA）。
    private let termsURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!

    private let benefits: [(icon: String, title: LocalizedStringKey, subtitle: LocalizedStringKey)] = [
        ("square.grid.3x3.fill", "paywall_benefit_templates_title", "paywall_benefit_templates_sub"),
        ("drop.fill", "paywall_benefit_watermark_title", "paywall_benefit_watermark_sub"),
        ("aspectratio.fill", "paywall_benefit_ratio_title", "paywall_benefit_ratio_sub"),
        ("sparkles", "paywall_benefit_updates_title", "paywall_benefit_updates_sub")
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    header
                    benefitList
                    purchaseSection
                    footer
                }
                .padding(24)
            }
            .background(backgroundGradient.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                            .font(.title2)
                    }
                    .accessibilityLabel(Text("close"))
                }
            }
            .onChange(of: store.isPro) { _, newValue in
                if newValue { dismiss() }
            }
            .sheet(isPresented: $showPrivacy) {
                PrivacyPolicyView()
            }
        }
    }

    // MARK: - 子视图

    private var header: some View {
        VStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .frame(width: 96, height: 96)
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
            }
            Text("paywall_title")
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
            Text("paywall_subtitle")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 12)
    }

    private var benefitList: some View {
        VStack(spacing: 14) {
            ForEach(benefits, id: \.title) { benefit in
                HStack(spacing: 16) {
                    Image(systemName: benefit.icon)
                        .font(.title2)
                        .foregroundStyle(Color.accentColor)
                        .frame(width: 38)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(benefit.title)
                            .font(.headline)
                        Text(benefit.subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
            }
        }
    }

    private var purchaseSection: some View {
        VStack(spacing: 12) {
            Button {
                Task {
                    isPurchasing = true
                    await store.purchasePro()
                    isPurchasing = false
                }
            } label: {
                HStack {
                    if isPurchasing {
                        ProgressView().tint(.white)
                    } else {
                        Text("paywall_unlock_button")
                            .fontWeight(.semibold)
                        Text(store.proDisplayPrice)
                            .fontWeight(.bold)
                    }
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(isPurchasing || store.isLoadingProducts)

            Button("paywall_restore") {
                Task { await store.restore() }
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
    }

    private var footer: some View {
        VStack(spacing: 6) {
            Text("paywall_onetime_note")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            HStack(spacing: 16) {
                Link("paywall_terms", destination: termsURL)
                Button("paywall_privacy") { showPrivacy = true }
            }
            .font(.caption2)
        }
        .padding(.bottom, 8)
    }

    private var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [Color.accentColor.opacity(0.18), Color(.systemBackground)],
            startPoint: .top,
            endPoint: .center
        )
    }
}

#Preview {
    PaywallView()
        .environmentObject(PurchaseManager())
}
