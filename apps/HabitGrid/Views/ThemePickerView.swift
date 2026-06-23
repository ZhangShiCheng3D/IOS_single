//
//  ThemePickerView.swift
//  HabitGrid
//
//  配色方案选择器。免费用户仅可选免费主题，付费主题需解锁。
//

import SwiftUI

struct ThemePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ThemeManager.self) private var themeManager
    @Environment(PurchaseManager.self) private var purchaseManager
    @Environment(\.colorScheme) private var scheme

    @State private var showingPaywall = false

    private let columns = [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(ColorPalette.all) { palette in
                        themeCard(palette)
                    }
                }
                .padding()
            }
            .navigationTitle("theme.title")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.done") { dismiss() }
                }
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView(reason: .premiumTheme)
            }
        }
    }

    private func themeCard(_ palette: ColorPalette) -> some View {
        let isSelected = themeManager.paletteID == palette.id
        let isLocked = palette.isPremium && !purchaseManager.isPro

        return Button {
            if isLocked {
                showingPaywall = true
            } else {
                Haptics.selection()
                withAnimation(Motion.spring) {
                    themeManager.paletteID = palette.id
                }
            }
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                // 迷你热力图样本
                HStack(spacing: 3) {
                    ForEach(0..<7, id: \.self) { col in
                        VStack(spacing: 3) {
                            ForEach(0..<4, id: \.self) { row in
                                RoundedRectangle(cornerRadius: 2, style: .continuous)
                                    .fill(palette.heatColor(intensity: (col + row) % 5, scheme: scheme))
                                    .frame(width: 12, height: 12)
                            }
                        }
                    }
                }

                HStack {
                    Text(palette.nameKey)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Spacer()
                    if isLocked {
                        Image(systemName: "lock.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.body)
                            .foregroundStyle(palette.accent)
                    }
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity)
            .background(.background, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(isSelected ? palette.accent : .clear, lineWidth: 2)
            }
            .cardShadow()
        }
        .buttonStyle(.plain)
    }
}

#Preview("Theme Picker") {
    ThemePickerView()
        .environment(ThemeManager())
        .environment(PurchaseManager())
}
