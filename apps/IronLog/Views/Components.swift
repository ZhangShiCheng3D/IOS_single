//
//  Components.swift
//  IronLog
//
//  跨页面复用的小型视图组件。
//

import SwiftUI

/// 训练摘要卡片：日期、动作数、组数、总容量、时长。
struct SessionSummaryCard: View {
    let session: WorkoutSession
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(session.name.isEmpty ? String(localized: "workout.untitled") : session.name)
                    .font(.headline)
                Spacer()
                Text(Fmt.relativeDay(session.date))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 18) {
                StatBadge(
                    icon: "figure.strengthtraining.traditional",
                    value: "\(session.exercises.count)",
                    label: String(localized: "stat.exercises")
                )
                StatBadge(
                    icon: "number",
                    value: "\(session.completedSetCount)",
                    label: String(localized: "stat.sets")
                )
                StatBadge(
                    icon: "scalemass",
                    value: Fmt.volume(session.totalVolume, unit: settings.weightUnit),
                    label: String(localized: "stat.volume")
                )
                StatBadge(
                    icon: "clock",
                    value: Fmt.duration(session.duration),
                    label: String(localized: "stat.duration")
                )
            }
        }
        .cardStyle()
    }
}

/// 小统计徽标（图标 + 数值 + 标签）。
struct StatBadge: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 3) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(Color.ironAccent)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

/// 肌群彩色标签。
struct MuscleChip: View {
    let group: MuscleGroup

    var body: some View {
        Text(LocalizedStringKey(group.localizedNameKey))
            .font(.caption2.weight(.medium))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Color(group.accentColorName).opacity(0.18),
                in: Capsule()
            )
            .foregroundStyle(Color(group.accentColorName))
    }
}

/// 大数值统计卡（用于趋势页顶部）。
struct MetricCard: View {
    let title: String
    let value: String
    let systemImage: String
    var tint: Color = .ironAccent

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: systemImage)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 16) {
            SessionSummaryCard(session: PreviewData.sampleSession)
            HStack {
                MetricCard(title: "总容量", value: "12,400 kg", systemImage: "scalemass")
                MetricCard(title: "训练次数", value: "23", systemImage: "flame")
            }
            HStack {
                MuscleChip(group: .chest)
                MuscleChip(group: .back)
                MuscleChip(group: .legs)
            }
        }
        .padding()
    }
    .environmentObject(AppSettings())
    .modelContainer(PreviewData.container)
}
