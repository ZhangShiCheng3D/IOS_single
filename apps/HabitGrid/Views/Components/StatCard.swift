//
//  StatCard.swift
//  HabitGrid
//
//  统计数字卡片组件。
//

import SwiftUI

/// 单个统计指标卡片（图标 + 数值 + 标题）。
struct StatCard: View {
    let icon: String
    let value: String
    let title: LocalizedStringKey
    var accent: Color = .green

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.callout)
                    .foregroundStyle(accent)
                Spacer()
            }
            Text(value)
                .font(.title2.bold())
                .contentTransition(.numericText())
                .monospacedDigit()
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .cardShadow()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(Text(value))
    }
}

/// 强调连续天数的“火焰”卡片。
struct StreakBadge: View {
    let streak: Int
    var accent: Color = .orange

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "flame.fill")
                .foregroundStyle(streak > 0 ? accent : .secondary)
                .symbolEffect(.bounce, value: streak)
            Text("\(streak)")
                .font(.subheadline.weight(.bold))
                .monospacedDigit()
                .contentTransition(.numericText())
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            (streak > 0 ? accent.opacity(0.15) : Color.secondary.opacity(0.12)),
            in: Capsule()
        )
        .foregroundStyle(streak > 0 ? accent : .secondary)
        .accessibilityLabel(Text("a11y.streak \(streak)"))
    }
}

#Preview("Stat Card") {
    VStack(spacing: 16) {
        HStack(spacing: 12) {
            StatCard(icon: "flame.fill", value: "12", title: "stats.currentStreak", accent: .orange)
            StatCard(icon: "trophy.fill", value: "30", title: "stats.longestStreak", accent: .yellow)
        }
        StreakBadge(streak: 7)
        StreakBadge(streak: 0)
    }
    .padding()
}
