//
//  PaywallView.swift
//  HabitGrid
//
//  付费墙：展示 Pro 权益、价格、购买与恢复按钮。
//

import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(PurchaseManager.self) private var purchaseManager
    @Environment(ThemeManager.self) private var themeManager

    /// 触发付费墙的来源（用于文案微调，可选）。
    var reason: PaywallReason = .general

    enum PaywallReason {
        case habitLimit   // 习惯数量超限
        case premiumTheme // 想用付费主题
        case general

        var headline: LocalizedStringKey {
            switch self {
            case .habitLimit:   return "paywall.reason.habitLimit"
            case .premiumTheme: return "paywall.reason.theme"
            case .general:      return "paywall.reason.general"
            }
        }
    }

    private var accent: Color { themeManager.palette.accent }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    header
                    benefitsList
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
                        Image(systemName: "xmark")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityLabel(Text("common.close"))
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await purchaseManager.restore() }
                    } label: {
                        Text("paywall.restore")
                            .font(.subheadline)
                    }
                }
            }
            .task {
                if purchaseManager.products.isEmpty {
                    await purchaseManager.loadProducts()
                }
            }
            .onChange(of: purchaseManager.isPro) { _, isPro in
                if isPro { dismiss() }
            }
        }
        .presentationDragIndicator(.visible)
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 16) {
            // 迷你热力图作为视觉锚点。
            MiniHeatmapBanner(palette: themeManager.palette)
                .frame(height: 64)
                .padding(.horizontal, 8)

            VStack(spacing: 8) {
                Text("paywall.title")
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)

                Text(reason.headline)
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, 12)
    }

    // MARK: - 权益列表

    private var benefitsList: some View {
        VStack(spacing: 14) {
            BenefitRow(icon: "infinity", title: "paywall.benefit.unlimited.title",
                       subtitle: "paywall.benefit.unlimited.subtitle", accent: accent)
            BenefitRow(icon: "paintpalette.fill", title: "paywall.benefit.themes.title",
                       subtitle: "paywall.benefit.themes.subtitle", accent: accent)
            BenefitRow(icon: "square.and.arrow.up.fill", title: "paywall.benefit.export.title",
                       subtitle: "paywall.benefit.export.subtitle", accent: accent)
            BenefitRow(icon: "bell.badge.fill", title: "paywall.benefit.reminders.title",
                       subtitle: "paywall.benefit.reminders.subtitle", accent: accent)
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    // MARK: - 购买区

    private var purchaseSection: some View {
        VStack(spacing: 12) {
            if let product = purchaseManager.proProduct {
                Button {
                    Task { await purchaseManager.purchase(product) }
                } label: {
                    HStack {
                        if purchaseManager.isPurchasing {
                            ProgressView().tint(.white)
                        } else {
                            Text("paywall.unlock")
                                .fontWeight(.bold)
                            Text(product.displayPrice)
                                .fontWeight(.bold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(accent, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .foregroundStyle(.white)
                }
                .disabled(purchaseManager.isPurchasing)

                Text("paywall.onetime")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                // 产品尚未加载（或在非真机环境）。
                ProgressView()
                    .frame(height: 54)
            }

            if let error = purchaseManager.lastErrorMessage {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private var legalLinks: some View {
        HStack(spacing: 16) {
            Link("paywall.terms", destination: LegalLinks.appleStandardEULA)
            Text("·").foregroundStyle(.tertiary)
            NavigationLink("paywall.privacy") {
                PrivacyPolicyView()
            }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }

    private var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [accent.opacity(0.12), .clear],
            startPoint: .top,
            endPoint: .center
        )
    }
}

// MARK: - 子组件

/// 单条权益行。
private struct BenefitRow: View {
    let icon: String
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey
    let accent: Color

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(accent)
                .frame(width: 36, height: 36)
                .background(accent.opacity(0.15), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.weight(.semibold))
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
    }
}

/// 付费墙顶部的装饰性迷你热力图条。
private struct MiniHeatmapBanner: View {
    let palette: ColorPalette
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        GeometryReader { geo in
            let columns = 26
            let spacing: CGFloat = 3
            let cell = (geo.size.width - spacing * CGFloat(columns - 1)) / CGFloat(columns)
            HStack(spacing: spacing) {
                ForEach(0..<columns, id: \.self) { col in
                    VStack(spacing: spacing) {
                        ForEach(0..<5, id: \.self) { row in
                            // 用确定性伪随机生成令人愉悦的渐变图案。
                            let intensity = patternIntensity(col: col, row: row)
                            RoundedRectangle(cornerRadius: 2, style: .continuous)
                                .fill(palette.heatColor(intensity: intensity, scheme: scheme))
                                .frame(width: cell, height: cell)
                        }
                    }
                }
            }
        }
    }

    private func patternIntensity(col: Int, row: Int) -> Int {
        let seed = (col * 7 + row * 13) % 11
        switch seed {
        case 0, 1, 2: return 0
        case 3, 4:    return 1
        case 5, 6, 7: return 2
        case 8, 9:    return 3
        default:      return 4
        }
    }
}

#Preview("Paywall") {
    PaywallView(reason: .habitLimit)
        .environment(PurchaseManager())
        .environment(ThemeManager())
}
