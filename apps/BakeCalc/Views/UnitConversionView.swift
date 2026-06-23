//
//  UnitConversionView.swift
//  BakeCalc
//
//  单位换算页面（免费）。重量、体积及借助密度的体积→重量交叉换算。
//

import SwiftUI

struct UnitConversionView: View {
    @StateObject private var vm = UnitConversionViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: BCMetrics.sectionSpacing) {
                modePicker

                ResultCard(
                    titleKey: "common.result",
                    value: vm.resultText,
                    unit: resultUnitLabel
                )

                inputCard
            }
            .padding()
        }
        .background(Color.bcBackground.ignoresSafeArea())
        .navigationTitle(Text("feature.unitConversion"))
        .navigationBarTitleDisplayMode(.large)
        .scrollDismissesKeyboard(.interactively)
    }

    // MARK: - 子视图

    private var modePicker: some View {
        Picker("convert.mode", selection: $vm.mode) {
            ForEach(ConversionMode.allCases) { mode in
                Text(LocalizedStringKey(mode.localizedKey)).tag(mode)
            }
        }
        .pickerStyle(.segmented)
    }

    @ViewBuilder
    private var inputCard: some View {
        VStack(spacing: 16) {
            NumberInputField(titleKey: "common.amount", text: $vm.inputText)

            switch vm.mode {
            case .weight:
                unitRow(
                    from: AnyView(weightMenu(selection: $vm.fromWeight)),
                    to: AnyView(weightMenu(selection: $vm.toWeight)),
                    showSwap: true
                )
            case .volume:
                unitRow(
                    from: AnyView(volumeMenu(selection: $vm.fromVolume)),
                    to: AnyView(volumeMenu(selection: $vm.toVolume)),
                    showSwap: true
                )
            case .volumeToWeight:
                ingredientPicker
                unitRow(
                    from: AnyView(volumeMenu(selection: $vm.crossFromVolume)),
                    to: AnyView(weightMenu(selection: $vm.crossToWeight)),
                    showSwap: false
                )
            }
        }
        .bcCard()
    }

    private func unitRow(from: AnyView, to: AnyView, showSwap: Bool) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("convert.from").font(.caption).foregroundStyle(.secondary)
                from
            }
            if showSwap {
                SwapButton { withAnimation(BCMotion.spring) { vm.swap() } }
                    .padding(.top, 18)
            } else {
                Image(systemName: "arrow.right")
                    .foregroundStyle(.secondary)
                    .padding(.top, 18)
            }
            VStack(alignment: .leading, spacing: 6) {
                Text("convert.to").font(.caption).foregroundStyle(.secondary)
                to
            }
        }
    }

    private var ingredientPicker: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("convert.ingredient").font(.caption).foregroundStyle(.secondary)
            Menu {
                ForEach(IngredientCategory.allCases) { category in
                    Section(LocalizedStringKey(category.localizedKey)) {
                        ForEach(BakingData.ingredients.filter { $0.category == category }) { ing in
                            Button {
                                vm.selectedIngredientID = ing.id
                            } label: {
                                Text(LocalizedStringKey(ing.nameKey))
                            }
                        }
                    }
                }
            } label: {
                menuLabel(
                    LocalizedStringKey(vm.selectedIngredient?.nameKey ?? "ingredient.water")
                )
            }
        }
    }

    private func weightMenu(selection: Binding<WeightUnit>) -> some View {
        Menu {
            ForEach(WeightUnit.allCases) { unit in
                Button { selection.wrappedValue = unit } label: {
                    Text(LocalizedStringKey(unit.localizedKey))
                }
            }
        } label: {
            menuLabel(LocalizedStringKey(selection.wrappedValue.localizedKey))
        }
    }

    private func volumeMenu(selection: Binding<VolumeUnit>) -> some View {
        Menu {
            ForEach(VolumeUnit.allCases) { unit in
                Button { selection.wrappedValue = unit } label: {
                    Text(LocalizedStringKey(unit.localizedKey))
                }
            }
        } label: {
            menuLabel(LocalizedStringKey(selection.wrappedValue.localizedKey))
        }
    }

    private func menuLabel(_ key: LocalizedStringKey) -> some View {
        HStack {
            Text(key)
                .foregroundStyle(.primary)
            Spacer()
            Image(systemName: "chevron.up.chevron.down")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(10)
        .frame(maxWidth: .infinity)
        .background(Color.bcBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var resultUnitLabel: String {
        switch vm.mode {
        case .weight:         return NSLocalizedString(vm.toWeight.localizedKey, comment: "")
        case .volume:         return NSLocalizedString(vm.toVolume.localizedKey, comment: "")
        case .volumeToWeight: return NSLocalizedString(vm.crossToWeight.localizedKey, comment: "")
        }
    }
}

#Preview("单位换算") {
    NavigationStack {
        UnitConversionView()
    }
    .environmentObject(PurchaseManager())
}
