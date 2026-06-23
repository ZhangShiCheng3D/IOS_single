//
//  PaywallView.swift
//  IronLog
//
//  买断付费墙。强调一次买断、永久解锁、纯本地无订阅。
//

import SwiftUI
import StoreKit

struct PaywallView: View {
    @EnvironmentObject private var purchaseManager: PurchaseManager
    @Environment(\.dismiss) private var dismiss

    /// Pro 卖点列表。
    private let benefits: [(icon: String, titleKey: String, subtitleKey: String)] = [
        ("infinity", "paywall.benefit.unlimited.title", "paywall.benefit.unlimited.sub"),
        ("chart.line.uptrend.xyaxis", "paywall.benefit.trends.title", "paywall.benefit.trends.sub"),
        ("crown.fill", "paywall.benefit.pr.title", "paywall.benefit.pr.sub"),
        ("square.and.arrow.up", "paywall.benefit.export.title", "paywall.benefit.export.sub"),
        ("heart.fill", "paywall.benefit.health.title", "paywall.benefit.health.sub"),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    header
                    benefitList
                    purchaseSection
                    footnote
                    legalLinks
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.body.weight(.semibold))
                    }
                    .accessibilityLabel(Text("common.close"))
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("paywall.restore") {
                        Task { await purchaseManager.restore() }
                    }
                    .font(.subheadline)
                }
            }
            .alert(
                "store.error.title",
                isPresented: .constant(purchaseManager.errorMessage != nil),
                actions: {
                    Button("common.ok") { purchaseManager.errorMessage = nil }
                },
                message: {
                    Text(purchaseManager.errorMessage ?? "")
                }
            )
            .onChange(of: purchaseManager.isPro) { _, isPro in
                if isPro { dismiss() }
            }
        }
    }

    // MARK: - 子视图

    private var header: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.ironAccent.opacity(0.15))
                    .frame(width: 92, height: 92)
                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(Color.ironAccent)
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
        VStack(spacing: 0) {
            ForEach(Array(benefits.enumerated()), id: \.offset) { index, benefit in
                HStack(spacing: 14) {
                    Image(systemName: benefit.icon)
                        .font(.title3)
                        .foregroundStyle(Color.ironAccent)
                        .frame(width: 32)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(LocalizedStringKey(benefit.titleKey))
                            .font(.body.weight(.semibold))
                        Text(LocalizedStringKey(benefit.subtitleKey))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(.vertical, 12)
                if index < benefits.count - 1 {
                    Divider().padding(.leading, 46)
                }
            }
        }
        .cardStyle()
    }

    private var purchaseSection: some View {
        VStack(spacing: 12) {
            Button {
                Task { await purchaseManager.purchasePro() }
            } label: {
                HStack {
                    if purchaseManager.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("paywall.buy")
                            .fontWeight(.bold)
                        Text(purchaseManager.displayPrice)
                            .fontWeight(.bold)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Color.ironAccent, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .foregroundStyle(.white)
            }
            .disabled(purchaseManager.isLoading)

            Label("paywall.onetime", systemImage: "checkmark.seal.fill")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var footnote: some View {
        Text("paywall.footnote")
            .font(.caption2)
            .foregroundStyle(.tertiary)
            .multilineTextAlignment(.center)
            .padding(.top, 4)
    }

    /// 条款与隐私入口（含内购的 App 须在购买界面提供，合规要求）。
    private var legalLinks: some View {
        HStack(spacing: 6) {
            Link("settings.terms", destination: AppLinks.termsOfUse)
            Text("·")
                .foregroundStyle(.tertiary)
            NavigationLink("settings.privacy") {
                PrivacyPolicyView()
            }
        }
        .font(.caption2)
        .tint(.secondary)
    }
}

#Preview {
    PaywallView()
        .environmentObject(PurchaseManager())
}
