//
//  OvenReferenceView.swift
//  BakeCalc
//
//  烤箱温度参考表（免费）。摄氏 / 华氏 / Gas Mark / 火力描述对照。
//

import SwiftUI

struct OvenReferenceView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                headerRow
                ForEach(BakingData.ovenReferences) { ref in
                    row(ref)
                }
            }
            .padding()
        }
        .background(Color.bcBackground.ignoresSafeArea())
        .navigationTitle(Text("feature.ovenReference"))
    }

    private var headerRow: some View {
        HStack {
            Text("temp.celsius").frame(maxWidth: .infinity, alignment: .leading)
            Text("temp.fahrenheit").frame(maxWidth: .infinity, alignment: .leading)
            Text("oven.gas_mark").frame(maxWidth: .infinity, alignment: .leading)
            Text("oven.heat").frame(maxWidth: .infinity, alignment: .trailing)
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(.secondary)
        .padding(.horizontal, 8)
    }

    private func row(_ ref: OvenReference) -> some View {
        HStack {
            Text("\(ref.celsius)°")
                .fontWeight(.semibold)
                .foregroundStyle(Color.bcAccent)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("\(ref.fahrenheit)°")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(ref.gasMark)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(LocalizedStringKey(ref.descriptionKey))
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 12)
        .background(Color.bcCard)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

#Preview("烤箱参考") {
    NavigationStack {
        OvenReferenceView()
    }
}
