//
//  StatChip.swift
//  FastFlow
//
//  小型统计信息卡片，用于展示开始时间、目标时间、剩余时长等。
//

import SwiftUI

struct StatChip: View {
    let icon: String
    let title: LocalizedStringKey
    let value: String
    var tint: Color = .accentColor

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(tint)
            Text(value)
                .font(.system(.headline, design: .rounded))
                .monospacedDigit()
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DS.Spacing.md - 2)
        .cardStyle()
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    HStack {
        StatChip(icon: "play.circle", title: "fasting.startedAt", value: "08:30")
        StatChip(icon: "flag.checkered", title: "fasting.goalAt", value: "00:30", tint: .goalReached)
        StatChip(icon: "hourglass", title: "fasting.remaining", value: "05:24", tint: .orange)
    }
    .padding()
}
