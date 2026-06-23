//
//  SharedComponents.swift
//  BakeCalc
//
//  跨页面复用的小型 SwiftUI 组件：结果卡片、数字输入框、分区标题、Pro 锁标记。
//

import SwiftUI

// MARK: - 大号结果展示卡

struct ResultCard: View {
    let titleKey: LocalizedStringKey
    let value: String
    let unit: String
    var accent: Bool = true

    var body: some View {
        VStack(spacing: 6) {
            Text(titleKey)
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(value)
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundStyle(accent ? Color.bcAccent : Color.primary)
                    .contentTransition(.numericText())
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                if !unit.isEmpty {
                    Text(unit)
                        .font(.title3.weight(.medium))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(
            LinearGradient(
                colors: [Color.bcAccent.opacity(0.10), Color.bcSecondary.opacity(0.10)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: BCMetrics.cornerRadius, style: .continuous))
        .animation(.snappy, value: value)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - 数字输入框

struct NumberInputField: View {
    let titleKey: LocalizedStringKey
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(titleKey)
                .font(.caption)
                .foregroundStyle(.secondary)
            TextField("", text: $text)
                .keyboardType(.decimalPad)
                .font(.title3.weight(.medium))
                .padding(12)
                .background(Color.bcCard)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.bcAccent.opacity(0.25), lineWidth: 1)
                )
        }
    }
}

// MARK: - 分区标题

struct SectionHeader: View {
    let titleKey: LocalizedStringKey
    var systemImage: String? = nil

    var body: some View {
        HStack(spacing: 6) {
            if let systemImage {
                Image(systemName: systemImage)
                    .foregroundStyle(Color.bcAccent)
            }
            Text(titleKey)
                .font(.headline)
            Spacer()
        }
    }
}

// MARK: - Pro 锁标记

struct ProBadge: View {
    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "crown.fill")
                .font(.system(size: 9, weight: .bold))
            Text("common.pro")
                .font(.system(size: 10, weight: .bold))
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(
            LinearGradient(colors: [Color.bcAccent, Color.bcSecondary],
                           startPoint: .leading, endPoint: .trailing)
        )
        .foregroundStyle(.white)
        .clipShape(Capsule())
    }
}

// MARK: - 交换按钮

struct SwapButton: View {
    let action: () -> Void
    var body: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            Image(systemName: "arrow.left.arrow.right.circle.fill")
                .font(.title2)
                .foregroundStyle(Color.bcAccent)
                .symbolRenderingMode(.hierarchical)
        }
        .accessibilityLabel(Text("common.swap"))
    }
}

#Preview("组件预览") {
    ScrollView {
        VStack(spacing: 20) {
            ResultCard(titleKey: "common.result", value: "453.6", unit: "g")
            NumberInputField(titleKey: "common.amount", text: .constant("100"))
            SectionHeader(titleKey: "common.result", systemImage: "scalemass")
            HStack { ProBadge(); SwapButton {} }
        }
        .padding()
    }
    .background(Color.bcBackground)
}
