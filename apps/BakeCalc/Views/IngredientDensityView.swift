//
//  IngredientDensityView.swift
//  BakeCalc
//
//  常见烘焙原料密度参数表（专业版）。支持搜索与按分类浏览，
//  展示每种原料的密度、每杯克数与每大勺克数。
//

import SwiftUI

struct IngredientDensityView: View {
    @State private var searchText = ""

    private var filtered: [IngredientCategory: [IngredientDensity]] {
        let matches = BakingData.ingredients.filter { ing in
            searchText.isEmpty ||
            NSLocalizedString(ing.nameKey, comment: "")
                .localizedCaseInsensitiveContains(searchText)
        }
        return Dictionary(grouping: matches, by: \.category)
    }

    var body: some View {
        List {
            ForEach(IngredientCategory.allCases) { category in
                if let items = filtered[category], !items.isEmpty {
                    Section {
                        ForEach(items) { ing in
                            row(ing)
                        }
                    } header: {
                        Label(LocalizedStringKey(category.localizedKey),
                              systemImage: category.systemImage)
                    }
                }
            }
        }
        .navigationTitle(Text("feature.densityTable"))
        .searchable(text: $searchText, prompt: Text("density.search"))
    }

    private func row(_ ing: IngredientDensity) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(LocalizedStringKey(ing.nameKey))
                .font(.subheadline.weight(.medium))
            HStack(spacing: 16) {
                stat("density.per_cup", "\(NumberFormatting.formatted(ing.gramsPerCup, maxFraction: 0)) g")
                stat("density.per_tbsp", "\(NumberFormatting.formatted(ing.gramsPerTablespoon, maxFraction: 1)) g")
                stat("density.value", "\(NumberFormatting.formatted(ing.gramsPerMilliliter, maxFraction: 2)) g/mL")
            }
        }
        .padding(.vertical, 4)
    }

    private func stat(_ labelKey: LocalizedStringKey, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(labelKey).font(.caption2).foregroundStyle(.secondary)
            Text(value).font(.footnote.weight(.semibold)).foregroundStyle(Color.bcAccent)
        }
    }
}

#Preview("密度表") {
    NavigationStack {
        IngredientDensityView()
    }
}
