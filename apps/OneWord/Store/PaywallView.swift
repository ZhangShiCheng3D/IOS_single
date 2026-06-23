//
//  PaywallView.swift
//  OneWord
//
//  Presents the AI insight upgrade. Lists the unlocked features, the localized
//  price from StoreKit, and purchase / restore actions.
//

import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(PurchaseManager.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var showingPrivacy = false

    private let features: [(icon: String, title: LocalizedStringKey, subtitle: LocalizedStringKey)] = [
        ("chart.xyaxis.line", "paywall.feature.trends.title", "paywall.feature.trends.subtitle"),
        ("sparkles", "paywall.feature.insights.title", "paywall.feature.insights.subtitle"),
        ("calendar.badge.clock", "paywall.feature.year.title", "paywall.feature.year.subtitle"),
        ("tag", "paywall.feature.keywords.title", "paywall.feature.keywords.subtitle")
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    header
                    featureList
                    purchaseSection
                    legalLinks
                }
                .padding(Theme.Spacing.lg)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityLabel("common.close")
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button("paywall.restore") {
                        Task { await store.restore() }
                    }
                    .font(.subheadline)
                }
            }
            .overlay {
                if store.isProcessing {
                    ProgressView().controlSize(.large)
                }
            }
            .sheet(isPresented: $showingPrivacy) { PrivacyPolicyView() }
            .onChange(of: store.isPremiumUnlocked) { _, unlocked in
                if unlocked { dismiss() }
            }
        }
    }

    private var header: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "sparkles")
                .font(.system(size: 52))
                .foregroundStyle(Theme.accent)
                .padding(.top, Theme.Spacing.md)
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
        VStack(spacing: Theme.Spacing.md) {
            ForEach(features, id: \.icon) { feature in
                HStack(spacing: Theme.Spacing.md) {
                    Image(systemName: feature.icon)
                        .font(.title2)
                        .foregroundStyle(Theme.accent)
                        .frame(width: 36)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(feature.title).font(.headline)
                        Text(feature.subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
            }
        }
        .cardStyle()
    }

    @ViewBuilder
    private var purchaseSection: some View {
        if let product = store.insightsProduct {
            VStack(spacing: Theme.Spacing.sm) {
                Button {
                    Task { await store.purchase(product) }
                } label: {
                    HStack {
                        Text("paywall.unlock")
                        Spacer()
                        Text(product.displayPrice).bold()
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(store.isProcessing)

                Text("paywall.oneTime")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } else {
            // Products not yet loaded (or offline) — keep the user informed.
            VStack(spacing: Theme.Spacing.sm) {
                ProgressView()
                Text("paywall.loading")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
        }
    }

    private var legalLinks: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Text("paywall.legal")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            HStack(spacing: Theme.Spacing.xs) {
                Link("paywall.terms", destination: Legal.termsOfUseURL)
                Text("·").foregroundStyle(.secondary)
                Button("paywall.privacy") { showingPrivacy = true }
            }
            .font(.caption2)
        }
    }
}

#Preview {
    PaywallView()
        .environment(PurchaseManager())
}
