//
//  EmptyStateView.swift
//  DocScanPro
//
//  通用空状态占位视图。
//

import SwiftUI

struct EmptyStateView: View {
    let systemImage: String
    let titleKey: LocalizedStringKey
    let messageKey: LocalizedStringKey
    var actionTitle: LocalizedStringKey? = nil
    var action: (() -> Void)? = nil

    /// 入场动画状态。
    @State private var appeared = false

    var body: some View {
        VStack(spacing: DS.Spacing.md) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.12))
                    .frame(width: 108, height: 108)
                Image(systemName: systemImage)
                    .font(.system(size: 48, weight: .medium))
                    .foregroundStyle(Color.accentColor)
            }
            .accessibilityHidden(true)
            .scaleEffect(appeared ? 1 : 0.85)
            .opacity(appeared ? 1 : 0)

            Text(titleKey)
                .font(.title3.bold())
            Text(messageKey)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DS.Spacing.xl)
            if let actionTitle, let action {
                Button(actionTitle) {
                    Haptics.tapMedium()
                    action()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.top, DS.Spacing.xxs)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .onAppear {
            withAnimation(DS.Motion.spring) { appeared = true }
        }
    }
}

#Preview {
    EmptyStateView(
        systemImage: "doc.text.viewfinder",
        titleKey: "documents.empty.title",
        messageKey: "documents.empty.message",
        actionTitle: "documents.empty.action",
        action: {}
    )
}
