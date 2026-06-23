//
//  RecipeScalingView.swift
//  BakeCalc
//
//  配方按份数缩放页面（专业版）。输入原始份数与目标份数，
//  所有原料用量按比例实时换算。
//

import SwiftUI

struct RecipeScalingView: View {
    @StateObject private var vm = RecipeScalingViewModel()
    @State private var editMode: EditMode = .inactive

    var body: some View {
        List {
            Section {
                servingsRow
            }

            Section {
                ForEach($vm.ingredients) { $ingredient in
                    IngredientScaleRow(
                        ingredient: $ingredient,
                        scaledText: vm.scaledAmount(for: ingredient)
                    )
                }
                .onDelete(perform: vm.removeIngredients)
                .onMove(perform: vm.moveIngredients)

                Button {
                    Haptics.tap()
                    withAnimation(BCMotion.spring) { vm.addIngredient() }
                } label: {
                    Label("scale.add_ingredient", systemImage: "plus.circle.fill")
                }
            } header: {
                Text("scale.ingredients")
            } footer: {
                Text("scale.footer")
            }
        }
        .navigationTitle(Text("feature.recipeScaling"))
        .scrollDismissesKeyboard(.interactively)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                EditButton()
            }
        }
        .environment(\.editMode, $editMode)
    }

    private var servingsRow: some View {
        HStack(spacing: 12) {
            compactField("scale.base_servings", text: $vm.baseServingsText)
            VStack(spacing: 2) {
                Image(systemName: "arrow.right")
                    .foregroundStyle(.secondary)
                Text(vm.factorText)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.bcAccent)
            }
            compactField("scale.target_servings", text: $vm.targetServingsText)
        }
        .padding(.vertical, 4)
    }

    private func compactField(_ titleKey: LocalizedStringKey, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(titleKey).font(.caption2).foregroundStyle(.secondary)
            TextField("", text: text)
                .keyboardType(.numberPad)
                .font(.title3.weight(.semibold))
                .multilineTextAlignment(.center)
                .padding(8)
                .background(Color.bcBackground)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .frame(maxWidth: .infinity)
    }
}

/// 配方缩放页中的单条原料行。
private struct IngredientScaleRow: View {
    @Binding var ingredient: ScalableIngredient
    let scaledText: String

    var body: some View {
        VStack(spacing: 8) {
            TextField("scale.ingredient_name", text: $ingredient.name)
                .font(.subheadline.weight(.medium))
            HStack(spacing: 8) {
                TextField("scale.amount", text: $ingredient.amountText)
                    .keyboardType(.decimalPad)
                    .frame(width: 70)
                    .padding(6)
                    .background(Color.bcBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                TextField("scale.unit", text: $ingredient.unitLabel)
                    .frame(width: 50)
                    .padding(6)
                    .background(Color.bcBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                Image(systemName: "arrow.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                HStack(spacing: 4) {
                    Text(scaledText)
                        .font(.headline)
                        .foregroundStyle(Color.bcAccent)
                    Text(ingredient.unitLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview("配方缩放") {
    NavigationStack {
        RecipeScalingView()
    }
}
