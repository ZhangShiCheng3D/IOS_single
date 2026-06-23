//
//  PrivacyPolicyView.swift
//  LumenPuzzle
//
//  应用内隐私政策。本作不收集任何数据、无追踪、无网络后端，
//  因此以「我们不收集任何信息」的诚恳声明形式直接在 App 内呈现，
//  满足 App Store Guideline 5.1.1 对隐私政策可访问性的要求。
//

import SwiftUI

struct PrivacyPolicyView: View {

    /// 是否以 sheet 形式呈现（付费墙内）。为 true 时显示关闭按钮。
    var presentedAsSheet: Bool = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            LinearGradient.lumenBackground.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    if presentedAsSheet {
                        HStack {
                            Spacer()
                            Button {
                                Haptics.selection()
                                dismiss()
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.headline)
                                    .foregroundStyle(Color.lumenTextSecondary)
                                    .frame(width: 36, height: 36)
                                    .background(Circle().fill(Color.lumenSurface.opacity(0.5)))
                            }
                            .accessibilityLabel(Text("a11y.close"))
                        }
                    }

                    Text("privacy.title")
                        .font(.title.weight(.semibold))
                        .foregroundStyle(Color.lumenText)

                    Text("privacy.updated")
                        .font(.caption)
                        .foregroundStyle(Color.lumenTextSecondary)

                    paragraph("privacy.body.intro")
                    paragraph("privacy.body.collection")
                    paragraph("privacy.body.local")
                    paragraph("privacy.body.purchase")
                    paragraph("privacy.body.children")
                    paragraph("privacy.body.contact")
                }
                .padding(Spacing.xl)
            }
        }
        .navigationTitle(Text("privacy.title"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func paragraph(_ key: LocalizedStringKey) -> some View {
        Text(key)
            .font(.callout)
            .foregroundStyle(Color.lumenText.opacity(0.92))
            .fixedSize(horizontal: false, vertical: true)
            .lineSpacing(4)
    }
}

#Preview {
    NavigationStack {
        PrivacyPolicyView()
    }
}
