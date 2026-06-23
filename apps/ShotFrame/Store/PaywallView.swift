//
//  PaywallView.swift
//  ShotFrame
//
//  The single screen that sells the Pro unlock. Presented as a sheet whenever a
//  user taps a Pro template, frame, or the unlock button.
//

import SwiftUI

struct PaywallView: View {
    @EnvironmentObject private var purchases: PurchaseManager
    @Environment(\.dismiss) private var dismiss

    /// Marketing rows shown in the feature list.
    private let features: [(icon: String, titleKey: LocalizedStringKey, subtitleKey: LocalizedStringKey)] = [
        ("square.grid.2x2.fill", "paywall.feature.templates.title", "paywall.feature.templates.subtitle"),
        ("iphone.gen3", "paywall.feature.frames.title", "paywall.feature.frames.subtitle"),
        ("square.and.arrow.up.on.square.fill", "paywall.feature.batch.title", "paywall.feature.batch.subtitle"),
        ("sparkles", "paywall.feature.watermark.title", "paywall.feature.watermark.subtitle"),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    header
                    featureList
                    purchaseButton
                    footer
                }
                .padding(24)
            }
            .background(backdrop.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                            .font(.title3)
                    }
                    .accessibilityLabel(Text("common.close"))
                }
            }
        }
        .task { await purchases.load() }
        .onChange(of: purchases.isPro) { _, isPro in
            if isPro { dismiss() }
        }
    }

    // MARK: - Sections

    private var header: some View {
        VStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color("AccentColor"), .purple],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 96, height: 96)
                    .shadow(color: .black.opacity(0.2), radius: 16, y: 8)
                Image(systemName: "wand.and.sparkles")
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .padding(.top, 12)

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
        VStack(spacing: 16) {
            ForEach(features, id: \.icon) { feature in
                HStack(spacing: 16) {
                    Image(systemName: feature.icon)
                        .font(.title2)
                        .foregroundStyle(Color("AccentColor"))
                        .frame(width: 40, height: 40)
                        .background(Color("AccentColor").opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(feature.titleKey)
                            .font(.headline)
                        Text(feature.subtitleKey)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 0)
                }
            }
        }
        .padding(20)
        .cardStyle(20)
    }

    private var purchaseButton: some View {
        VStack(spacing: 12) {
            Button {
                Task { await purchases.purchasePro() }
            } label: {
                ZStack {
                    if purchases.isPurchasing {
                        ProgressView().tint(.white)
                    } else {
                        Text("paywall.unlock \(purchases.displayPrice)")
                            .font(.headline)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .foregroundStyle(.white)
                .background(
                    LinearGradient(
                        colors: [Color("AccentColor"), .purple],
                        startPoint: .leading, endPoint: .trailing
                    ),
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                )
            }
            .disabled(purchases.isPurchasing)

            Text("paywall.onetime")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var footer: some View {
        VStack(spacing: 16) {
            Button("paywall.restore") {
                Task { await purchases.restore() }
            }
            .font(.subheadline)

            HStack(spacing: 4) {
                Link("paywall.terms", destination: AppLinks.terms)
                Text("·").foregroundStyle(.secondary)
                Link("paywall.privacy", destination: AppLinks.privacy)
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
        .padding(.bottom, 8)
        .alert(
            "common.error",
            isPresented: Binding(
                get: { purchases.lastError != nil },
                set: { if !$0 { purchases.lastError = nil } }
            )
        ) {
            Button("common.ok", role: .cancel) { purchases.lastError = nil }
        } message: {
            Text(purchases.lastError ?? "")
        }
    }

    private var backdrop: some View {
        LinearGradient(
            colors: [Color("AccentColor").opacity(0.08), .clear],
            startPoint: .top, endPoint: .center
        )
    }
}

#Preview {
    PaywallView()
        .environmentObject(PurchaseManager())
}
