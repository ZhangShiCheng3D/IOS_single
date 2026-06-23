//
//  TemperatureView.swift
//  BakeCalc
//
//  温度换算页面（免费）。摄氏 ↔ 华氏，并提示最接近的烤箱档位。
//

import SwiftUI

struct TemperatureView: View {
    @StateObject private var vm = TemperatureViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: BCMetrics.sectionSpacing) {
                ResultCard(
                    titleKey: "common.result",
                    value: vm.resultText,
                    unit: vm.outputScale.symbol
                )

                inputCard

                if let oven = vm.closestOven {
                    ovenHint(oven)
                }
            }
            .padding()
        }
        .background(Color.bcBackground.ignoresSafeArea())
        .navigationTitle(Text("feature.temperature"))
        .scrollDismissesKeyboard(.interactively)
    }

    private var inputCard: some View {
        VStack(spacing: 16) {
            HStack(alignment: .bottom, spacing: 12) {
                NumberInputField(titleKey: "temp.input", text: $vm.inputText)
                Picker("temp.scale", selection: $vm.inputScale) {
                    ForEach(TemperatureScale.allCases) { scale in
                        Text(scale.symbol).tag(scale)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 120)
            }
            Button {
                Haptics.tap()
                withAnimation(BCMotion.spring) { vm.toggleScale() }
            } label: {
                Label("temp.toggle", systemImage: "arrow.up.arrow.down")
                    .font(.subheadline)
            }
        }
        .bcCard()
    }

    private func ovenHint(_ oven: OvenReference) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(titleKey: "temp.closest_oven", systemImage: "oven")
            HStack(spacing: 16) {
                ovenStat("\(oven.celsius)°C", "temp.celsius")
                Divider().frame(height: 32)
                ovenStat("\(oven.fahrenheit)°F", "temp.fahrenheit")
                Divider().frame(height: 32)
                ovenStat("Gas \(oven.gasMark)", "oven.gas_mark")
            }
            Text(LocalizedStringKey(oven.descriptionKey))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .bcCard()
    }

    private func ovenStat(_ value: String, _ labelKey: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.headline)
                .foregroundStyle(Color.bcAccent)
            Text(LocalizedStringKey(labelKey))
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview("温度换算") {
    NavigationStack {
        TemperatureView()
    }
    .environmentObject(PurchaseManager())
}
