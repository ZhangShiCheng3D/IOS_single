//
//  HabitGridWidget.swift
//  HabitGridWidget
//
//  主屏小组件：展示今日习惯完成情况。支持 small / medium 尺寸。
//  数据来自 App Group 共享的 HabitSnapshot，无需访问 SwiftData。
//

import WidgetKit
import SwiftUI

// MARK: - Timeline Entry

struct HabitWidgetEntry: TimelineEntry {
    let date: Date
    let snapshots: [HabitSnapshot]
}

// MARK: - Provider

struct HabitProvider: TimelineProvider {

    func placeholder(in context: Context) -> HabitWidgetEntry {
        HabitWidgetEntry(date: .now, snapshots: HabitProvider.sampleSnapshots)
    }

    func getSnapshot(in context: Context, completion: @escaping (HabitWidgetEntry) -> Void) {
        let snapshots = context.isPreview ? HabitProvider.sampleSnapshots : WidgetDataBridge.load()
        completion(HabitWidgetEntry(date: .now, snapshots: snapshots))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<HabitWidgetEntry>) -> Void) {
        let entry = HabitWidgetEntry(date: .now, snapshots: WidgetDataBridge.load())
        // 次日 0 点刷新，重置“今日完成”状态。
        let nextMidnight = Calendar.current.nextDate(
            after: .now,
            matching: DateComponents(hour: 0, minute: 0),
            matchingPolicy: .nextTime
        ) ?? Date.now.addingTimeInterval(3600)
        completion(Timeline(entries: [entry], policy: .after(nextMidnight)))
    }

    static let sampleSnapshots: [HabitSnapshot] = [
        HabitSnapshot(id: UUID(), name: "阅读", iconName: "book.fill", colorHex: "#8B5CF6", isCompletedToday: true, currentStreak: 12),
        HabitSnapshot(id: UUID(), name: "晨跑", iconName: "figure.run", colorHex: "#F97316", isCompletedToday: false, currentStreak: 3),
        HabitSnapshot(id: UUID(), name: "喝水", iconName: "drop.fill", colorHex: "#06B6D4", isCompletedToday: true, currentStreak: 7),
        HabitSnapshot(id: UUID(), name: "冥想", iconName: "brain.head.profile", colorHex: "#10B981", isCompletedToday: false, currentStreak: 0)
    ]
}

// MARK: - Widget View

struct HabitGridWidgetEntryView: View {
    var entry: HabitWidgetEntry
    @Environment(\.widgetFamily) private var family

    private var completedCount: Int { entry.snapshots.filter { $0.isCompletedToday }.count }

    var body: some View {
        switch family {
        case .systemSmall:
            smallView
        default:
            mediumView
        }
    }

    // MARK: Small

    private var smallView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "square.grid.3x3.fill")
                    .font(.caption)
                    .foregroundStyle(.tint)
                Spacer()
                Text("\(completedCount)/\(entry.snapshots.count)")
                    .font(.caption.weight(.bold))
                    .monospacedDigit()
            }
            Spacer()
            // 今日完成进度圆点
            ringSummary
            Spacer()
            Text(completedCount == entry.snapshots.count && !entry.snapshots.isEmpty
                 ? "widget.allDone" : "widget.today")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(12)
    }

    private var ringSummary: some View {
        let total = max(entry.snapshots.count, 1)
        let progress = Double(completedCount) / Double(total)
        return ZStack {
            Circle().stroke(Color.secondary.opacity(0.2), lineWidth: 8)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(.tint, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(Int(progress * 100))%")
                .font(.headline.weight(.bold))
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: Medium

    private var mediumView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("widget.today")
                    .font(.subheadline.weight(.bold))
                Spacer()
                Text("\(completedCount)/\(entry.snapshots.count)")
                    .font(.caption.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }

            if entry.snapshots.isEmpty {
                Spacer()
                Text("widget.empty")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                Spacer()
            } else {
                ForEach(entry.snapshots.prefix(4)) { habit in
                    habitRow(habit)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(14)
    }

    private func habitRow(_ habit: HabitSnapshot) -> some View {
        let color = Color(hex: habit.colorHex) ?? .green
        return HStack(spacing: 10) {
            Image(systemName: habit.iconName)
                .font(.caption)
                .foregroundStyle(color)
                .frame(width: 22, height: 22)
                .background(color.opacity(0.15), in: RoundedRectangle(cornerRadius: 6, style: .continuous))

            Text(habit.name)
                .font(.caption.weight(.medium))
                .lineLimit(1)

            Spacer(minLength: 4)

            if habit.currentStreak > 0 {
                HStack(spacing: 2) {
                    Image(systemName: "flame.fill").font(.system(size: 9))
                    Text("\(habit.currentStreak)").font(.caption2.weight(.bold)).monospacedDigit()
                }
                .foregroundStyle(color)
            }

            Image(systemName: habit.isCompletedToday ? "checkmark.circle.fill" : "circle")
                .font(.callout)
                .foregroundStyle(habit.isCompletedToday ? color : Color.secondary.opacity(0.4))
        }
    }
}

// MARK: - Widget

struct HabitGridWidget: Widget {
    let kind = "HabitGridWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HabitProvider()) { entry in
            HabitGridWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName(Text("widget.displayName"))
        .description(Text("widget.description"))
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview("Small", as: .systemSmall) {
    HabitGridWidget()
} timeline: {
    HabitWidgetEntry(date: .now, snapshots: HabitProvider.sampleSnapshots)
}

#Preview("Medium", as: .systemMedium) {
    HabitGridWidget()
} timeline: {
    HabitWidgetEntry(date: .now, snapshots: HabitProvider.sampleSnapshots)
}
