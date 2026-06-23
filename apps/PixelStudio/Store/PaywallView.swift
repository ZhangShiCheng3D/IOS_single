//
//  PaywallView.swift
//  PixelStudio
//
//  买断付费墙。展示 Pro 能力清单、价格、购买与恢复按钮。
//

import SwiftUI
import StoreKit

struct PaywallView: View {
    @EnvironmentObject private var purchaseManager: PurchaseManager
    @Environment(\.dismiss) private var dismiss

    /// 触发付费墙的功能（用于高亮对应卖点，可为空）。
    var highlightedFeature: ProFeature?

    @State private var showingPrivacy = false

    private let benefits: [(icon: String, titleKey: LocalizedStringKey, detailKey: LocalizedStringKey)] = [
        ("square.resize", "pro.feature.largeCanvas.title", "pro.feature.largeCanvas.detail"),
        ("square.stack.3d.up", "pro.feature.extraLayers.title", "pro.feature.extraLayers.detail"),
        ("play.rectangle", "pro.feature.animation.title", "pro.feature.animation.detail"),
        ("square.and.arrow.up", "pro.feature.gifExport.title", "pro.feature.gifExport.detail")
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    header
                    benefitList
                    purchaseSection
                    legalLinks
                }
                .padding(24)
            }
            .background(backgroundGradient.ignoresSafeArea())
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                            .font(.title2)
                    }
                    .accessibilityLabel(Text("common.close"))
                }
            }
            .task { await purchaseManager.loadProducts() }
            .onChange(of: purchaseManager.isProUnlocked) { _, unlocked in
                if unlocked { dismiss() }
            }
        }
    }

    // MARK: - 子视图

    private var header: some View {
        VStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(LinearGradient(colors: [Color.accentColor, Color.accentColor.opacity(0.6)],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 84, height: 84)
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 40, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .shadow(color: Color.accentColor.opacity(0.4), radius: 12, y: 6)

            Text("paywall.title")
                .font(.title.bold())
                .multilineTextAlignment(.center)
            Text("paywall.subtitle")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 12)
    }

    private var benefitList: some View {
        VStack(spacing: 14) {
            ForEach(benefits, id: \.icon) { benefit in
                HStack(spacing: 14) {
                    Image(systemName: benefit.icon)
                        .font(.title3)
                        .foregroundStyle(Color.accentColor)
                        .frame(width: 36, height: 36)
                        .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(benefit.titleKey).font(.headline)
                        Text(benefit.detailKey)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(12)
                .background(highlightBackground(for: benefit.titleKey),
                            in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
    }

    private var purchaseSection: some View {
        VStack(spacing: 12) {
            Button {
                Task { await purchaseManager.purchasePro() }
            } label: {
                HStack {
                    if purchaseManager.isProcessing {
                        ProgressView().tint(.white)
                    } else {
                        Text("paywall.buy")
                        if !purchaseManager.proPriceText.isEmpty {
                            Text("· \(purchaseManager.proPriceText)").bold()
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .foregroundStyle(.white)
                .font(.headline)
            }
            .disabled(purchaseManager.isProcessing)

            Button {
                Task { await purchaseManager.restorePurchases() }
            } label: {
                Text("paywall.restore")
                    .font(.subheadline)
            }
            .disabled(purchaseManager.isProcessing)

            Text("paywall.oneTime")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var legalLinks: some View {
        HStack(spacing: 16) {
            Link("paywall.terms", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
            Button("paywall.privacy") { showingPrivacy = true }
        }
        .font(.caption2)
        .foregroundStyle(.secondary)
        .sheet(isPresented: $showingPrivacy) {
            NavigationStack {
                PrivacyPolicyView(presentedAsSheet: true)
            }
        }
    }

    private var backgroundGradient: LinearGradient {
        LinearGradient(colors: [Color(.systemBackground), Color.accentColor.opacity(0.06)],
                       startPoint: .top, endPoint: .bottom)
    }

    private func highlightBackground(for titleKey: LocalizedStringKey) -> Color {
        guard let feature = highlightedFeature else { return Color(.secondarySystemBackground) }
        return feature.titleKey == titleKey
            ? Color.accentColor.opacity(0.14)
            : Color(.secondarySystemBackground)
    }
}

#Preview {
    PaywallView(highlightedFeature: .animation)
        .environmentObject(PurchaseManager())
}
