//
//  PaywallView.swift
//  RetroFilm
//
//  The single-purchase paywall for unlocking every premium film stock.
//  Presented when the user taps a locked stock or the "Unlock All" button.
//

import SwiftUI

struct PaywallView: View {
    @EnvironmentObject private var store: PurchaseManager
    @Environment(\.dismiss) private var dismiss
    @State private var showPrivacy = false

    /// Premium stocks previewed as the "what you get" grid.
    private let premiumStocks = FilmStock.catalog.filter(\.isPremium)

    var body: some View {
        ZStack {
            Theme.filmBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    header
                    featureList
                    stockShowcase
                    Spacer(minLength: 8)
                    purchaseSection
                    legalLinks
                }
                .padding(24)
            }
        }
        .overlay(alignment: .topTrailing) {
            Button { dismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                    .padding()
            }
            .accessibilityLabel(Text("action.close"))
        }
        .sheet(isPresented: $showPrivacy) {
            NavigationStack { PrivacyPolicyView() }
        }
        .onChange(of: store.purchaseState) { _, state in
            if state == .success { dismiss() }
        }
        .interactiveDismissDisabled(store.purchaseState == .purchasing)
    }

    // MARK: Sections

    private var header: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Theme.warmGradient)
                    .frame(width: 84, height: 84)
                    .shadow(color: .orange.opacity(0.4), radius: 16, y: 6)
                Image(systemName: "camera.filters")
                    .font(.system(size: 38, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .padding(.top, 12)

            Text("paywall.title")
                .font(Theme.displayFont(28))
                .multilineTextAlignment(.center)
            Text("paywall.subtitle")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var featureList: some View {
        VStack(alignment: .leading, spacing: 16) {
            FeatureRow(icon: "film.stack", titleKey: "paywall.feature.stocks.title",
                       subtitleKey: "paywall.feature.stocks.subtitle")
            FeatureRow(icon: "slider.horizontal.3", titleKey: "paywall.feature.tune.title",
                       subtitleKey: "paywall.feature.tune.subtitle")
            FeatureRow(icon: "sparkles", titleKey: "paywall.feature.effects.title",
                       subtitleKey: "paywall.feature.effects.subtitle")
            FeatureRow(icon: "lock.open", titleKey: "paywall.feature.forever.title",
                       subtitleKey: "paywall.feature.forever.subtitle")
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardBackground()
    }

    private var stockShowcase: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("paywall.included")
                .font(.headline)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 76), spacing: 12)], spacing: 12) {
                ForEach(premiumStocks) { stock in
                    VStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(stock.swatch.gradient)
                            .frame(height: 56)
                            .overlay(
                                Text(stock.shortLabel)
                                    .font(.caption2.bold())
                                    .foregroundStyle(.white)
                                    .shadow(radius: 2)
                            )
                        Text(LocalizedStringKey(stock.id))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }
        }
    }

    private var purchaseSection: some View {
        VStack(spacing: 12) {
            Button(action: { Task { await store.purchase() } }) {
                HStack {
                    if store.purchaseState == .purchasing {
                        ProgressView().tint(.white)
                    } else {
                        Text("paywall.cta")
                            .font(.headline)
                        Text(store.formattedPrice)
                            .font(.headline.bold())
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Theme.warmGradient, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .foregroundStyle(.white)
                .softShadow(radius: 16, y: 8)
            }
            .disabled(store.purchaseState == .purchasing)

            Text("paywall.onetime")
                .font(.caption)
                .foregroundStyle(.secondary)

            if store.purchaseState == .pending {
                Text("paywall.pending")
                    .font(.caption)
                    .foregroundStyle(Theme.accent)
                    .multilineTextAlignment(.center)
            }

            if case .failed(let message) = store.purchaseState {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private var legalLinks: some View {
        HStack(spacing: 18) {
            Button("paywall.restore") { Task { await store.restore() } }
            Link("paywall.terms", destination: Legal.termsURL)
            Button("paywall.privacy") { showPrivacy = true }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.bottom, 8)
    }
}

private struct FeatureRow: View {
    let icon: String
    let titleKey: LocalizedStringKey
    let subtitleKey: LocalizedStringKey

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Theme.accent)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(titleKey).font(.subheadline.weight(.semibold))
                Text(subtitleKey).font(.caption).foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    PaywallView()
        .environmentObject(PurchaseManager())
}
