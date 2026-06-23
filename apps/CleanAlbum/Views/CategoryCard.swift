//
//  CategoryCard.swift
//  CleanAlbum
//
//  首页分类入口卡片（重复 / 相似 / 模糊）。
//

import SwiftUI

struct CategoryCard: View {
    let kind: PhotoGroupKind
    let photoCount: Int
    let groupCount: Int

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: Layout.cornerRadiusMD, style: .continuous)
                    .fill(Color.brand.opacity(0.12))
                    .frame(width: Layout.iconChip, height: Layout.iconChip)
                Image(systemName: kind.systemImage)
                    .font(.title2)
                    .foregroundStyle(Color.brand)
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: Layout.spacingXS) {
                Text(LocalizedStringKey(kind.titleKey))
                    .font(.headline)
                Text(String(format: String(localized: "category.summary"), photoCount, groupCount))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
        }
        .cardSurface()
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    VStack {
        CategoryCard(kind: .duplicate, photoCount: 24, groupCount: 6)
        CategoryCard(kind: .similar, photoCount: 58, groupCount: 12)
        CategoryCard(kind: .blurry, photoCount: 13, groupCount: 1)
    }
    .padding()
}
