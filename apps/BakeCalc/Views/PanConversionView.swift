//
//  PanConversionView.swift
//  BakeCalc
//
//  圆模/方模尺寸换算页面（专业版）。按底面积比例换算配方用量，
//  并提供一个示例用量输入框直观演示换算效果。
//

import SwiftUI

struct PanConversionView: View {
    @StateObject private var vm = PanConversionViewModel()
    @State private var sampleAmountText = "200"

    private var sampleResult: String {
        guard let amount = NumberFormatting.parse(sampleAmountText) else { return "—" }
        return vm.scaled(amount).bcSmart
    }

    var body: some View {
        ScrollView {
            VStack(spacing: BCMetrics.sectionSpacing) {
                ResultCard(titleKey: "pan.ratio", value: vm.ratioText, unit: "")

                panSelectionCard
                sampleCard
            }
            .padding()
        }
        .background(Color.bcBackground.ignoresSafeArea())
        .navigationTitle(Text("feature.panConversion"))
        .scrollDismissesKeyboard(.interactively)
    }

    private var panSelectionCard: some View {
        VStack(spacing: 16) {
            panMenu(titleKey: "pan.from", selection: $vm.fromPan, areaText: vm.fromAreaText)
            HStack {
                Spacer()
                SwapButton { withAnimation(BCMotion.spring) { vm.swap() } }
                Spacer()
            }
            panMenu(titleKey: "pan.to", selection: $vm.toPan, areaText: vm.toAreaText)
        }
        .bcCard()
    }

    private func panMenu(titleKey: LocalizedStringKey, selection: Binding<PanSize>, areaText: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(titleKey).font(.caption).foregroundStyle(.secondary)
            Menu {
                ForEach(PanShape.allCases) { shape in
                    Section(LocalizedStringKey(shape.localizedKey)) {
                        ForEach(BakingData.panSizes.filter { $0.shape == shape }) { pan in
                            Button {
                                selection.wrappedValue = pan
                            } label: {
                                Text(LocalizedStringKey(pan.nameKey))
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    Image(systemName: selection.wrappedValue.shape.systemImage)
                        .foregroundStyle(Color.bcAccent)
                    Text(LocalizedStringKey(selection.wrappedValue.nameKey))
                        .foregroundStyle(.primary)
                    Spacer()
                    Text("\(areaText) cm²")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(12)
                .background(Color.bcBackground)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
    }

    private var sampleCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(titleKey: "pan.sample", systemImage: "scalemass")
            HStack(spacing: 12) {
                NumberInputField(titleKey: "pan.sample_amount", text: $sampleAmountText)
                Image(systemName: "arrow.right").foregroundStyle(.secondary).padding(.top, 18)
                VStack(alignment: .leading, spacing: 6) {
                    Text("common.result").font(.caption).foregroundStyle(.secondary)
                    HStack(spacing: 4) {
                        Text(sampleResult)
                            .font(.title3.weight(.bold))
                            .foregroundStyle(Color.bcAccent)
                        Text("g").font(.caption).foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(Color.bcBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
            Text("pan.footer")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .bcCard()
    }
}

#Preview("模具换算") {
    NavigationStack {
        PanConversionView()
    }
}
