//
//  EggConversionView.swift
//  BakeCalc
//
//  鸡蛋个数 ↔ 重量精确换算页面（专业版）。按所选规格与部位
//  （全蛋/蛋白/蛋黄）的标准净重计算。
//

import SwiftUI

struct EggConversionView: View {
    @StateObject private var vm = EggConversionViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: BCMetrics.sectionSpacing) {
                ResultCard(
                    titleKey: "common.result",
                    value: vm.resultText,
                    unit: NSLocalizedString(vm.resultUnitKey, comment: "")
                )

                if let suggestion = vm.roundedSuggestion {
                    roundingHint(suggestion)
                }

                inputCard
                gradeCard
            }
            .padding()
        }
        .background(Color.bcBackground.ignoresSafeArea())
        .navigationTitle(Text("feature.eggConversion"))
        .scrollDismissesKeyboard(.interactively)
    }

    private var inputCard: some View {
        VStack(spacing: 16) {
            Picker("egg.direction", selection: $vm.direction) {
                ForEach(EggDirection.allCases) { dir in
                    Text(LocalizedStringKey(dir.localizedKey)).tag(dir)
                }
            }
            .pickerStyle(.segmented)

            NumberInputField(
                titleKey: vm.direction == .countToWeight ? "egg.count_input" : "egg.weight_input",
                text: $vm.inputText
            )

            Picker("egg.part", selection: $vm.part) {
                ForEach(EggPart.allCases) { part in
                    Text(LocalizedStringKey(part.localizedKey)).tag(part)
                }
            }
            .pickerStyle(.segmented)
        }
        .bcCard()
    }

    private var gradeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(titleKey: "egg.grade", systemImage: "oval.portrait")
            ForEach(BakingData.eggGrades) { grade in
                Button {
                    Haptics.selection()
                    withAnimation(BCMotion.spring) { vm.grade = grade }
                } label: {
                    HStack {
                        Image(systemName: vm.grade.id == grade.id ? "largecircle.fill.circle" : "circle")
                            .foregroundStyle(Color.bcAccent)
                        Text(LocalizedStringKey(grade.nameKey))
                            .foregroundStyle(.primary)
                        Spacer()
                        Text("\(NumberFormatting.formatted(grade.wholeGrams, maxFraction: 0)) g")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                if grade.id != BakingData.eggGrades.last?.id {
                    Divider()
                }
            }
        }
        .bcCard()
    }

    private func roundingHint(_ suggestion: (down: Int, up: Int)) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "lightbulb.fill")
                .foregroundStyle(Color.bcAccent)
            Text(String(
                format: NSLocalizedString("egg.rounding_hint", comment: ""),
                suggestion.down, suggestion.up
            ))
            .font(.caption)
            .foregroundStyle(.secondary)
            Spacer()
        }
        .bcCard()
    }
}

#Preview("鸡蛋换算") {
    NavigationStack {
        EggConversionView()
    }
}
