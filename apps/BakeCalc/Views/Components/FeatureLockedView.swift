//
//  FeatureLockedView.swift
//  BakeCalc
//
//  专业功能未解锁时展示的占位界面，引导用户进入付费墙。
//  搭配 ProGate 修饰符使用，集中处理「免费/付费」分流。
//

import SwiftUI

struct FeatureLockedView: View {
    let titleKey: LocalizedStringKey
    let onUnlock: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.bcAccent.opacity(0.12))
                    .frame(width: 96, height: 96)
                Image(systemName: "lock.fill")
                    .font(.system(size: 38, weight: .semibold))
                    .foregroundStyle(Color.bcAccent)
            }

            VStack(spacing: 8) {
                Text(titleKey)
                    .font(.title3.bold())
                    .multilineTextAlignment(.center)
                Text("locked.message")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Button(action: onUnlock) {
                Label("locked.cta", systemImage: "crown.fill")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(colors: [Color.bcAccent, Color.bcSecondary],
                                       startPoint: .leading, endPoint: .trailing)
                    )
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .padding(.horizontal, 32)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.bcBackground.ignoresSafeArea())
    }
}

// MARK: - Pro 分流修饰符

/// 当功能需要 Pro 且未解锁时，用锁定占位替换内容，并可弹出付费墙。
struct ProGate: ViewModifier {
    let feature: AppFeature
    let titleKey: LocalizedStringKey
    @EnvironmentObject private var purchaseManager: PurchaseManager
    @State private var showPaywall = false

    func body(content: Content) -> some View {
        Group {
            if purchaseManager.isUnlocked(feature) {
                content
            } else {
                FeatureLockedView(titleKey: titleKey) { showPaywall = true }
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
                .environmentObject(purchaseManager)
        }
    }
}

extension View {
    /// 对需要专业版的功能页面应用门禁。
    func proGate(_ feature: AppFeature, titleKey: LocalizedStringKey) -> some View {
        modifier(ProGate(feature: feature, titleKey: titleKey))
    }
}

#Preview("锁定页") {
    FeatureLockedView(titleKey: "feature.recipeScaling") {}
        .environmentObject(PurchaseManager())
}
