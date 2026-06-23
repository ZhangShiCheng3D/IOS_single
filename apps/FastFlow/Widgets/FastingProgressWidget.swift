//
//  FastingProgressWidget.swift
//  FastFlowWidget
//
//  主屏 Widget：展示当前断食进度（圆环 + 计时），空闲时提示开始。
//  数据来源为 App Group 共享快照（SharedStore）。
//

import SwiftUI
import WidgetKit

// MARK: - Timeline

struct FastingEntry: TimelineEntry {
    let date: Date
    let snapshot: FastingSnapshot
}

struct FastingTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> FastingEntry {
        FastingEntry(date: .now, snapshot: .idle)
    }

    func getSnapshot(in context: Context, completion: @escaping (FastingEntry) -> Void) {
        completion(FastingEntry(date: .now, snapshot: SharedStore.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FastingEntry>) -> Void) {
        let snapshot = SharedStore.load()
        let now = Date.now
        // 每 5 分钟刷新一次进度；走时由 Text(timerInterval:) 实时显示。
        var entries: [FastingEntry] = []
        for minute in stride(from: 0, to: 60, by: 5) {
            let date = now.addingTimeInterval(Double(minute) * 60)
            entries.append(FastingEntry(date: date, snapshot: snapshot))
        }
        completion(Timeline(entries: entries, policy: .after(now.addingTimeInterval(3600))))
    }
}

// MARK: - Widget

struct FastingProgressWidget: Widget {
    let kind = "FastingProgressWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FastingTimelineProvider()) { entry in
            FastingWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("widget.fasting.name")
        .description("widget.fasting.desc")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular])
    }
}

// MARK: - 视图

struct FastingWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: FastingEntry

    private var progress: Double {
        let s = entry.snapshot
        guard s.isFasting else { return 0 }
        let total = s.targetEndTime.timeIntervalSince(s.startTime)
        guard total > 0 else { return 0 }
        let elapsed = entry.date.timeIntervalSince(s.startTime)
        return min(1, max(0, elapsed / total))
    }

    var body: some View {
        switch family {
        case .accessoryCircular:
            accessoryView
        case .systemMedium:
            mediumView
        default:
            smallView
        }
    }

    private var smallView: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 8)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        AngularGradient(colors: [.accentColor, .green], center: .center),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                Image(systemName: entry.snapshot.isFasting ? "timer" : "moon.stars.fill")
                    .font(.title3)
                    .foregroundStyle(Color.accentColor)
            }
            .frame(width: 70, height: 70)

            if entry.snapshot.isFasting {
                Text(timerInterval: entry.snapshot.startTime...entry.snapshot.targetEndTime, countsDown: false)
                    .font(.caption.weight(.semibold))
                    .monospacedDigit()
                    .multilineTextAlignment(.center)
            } else {
                Text("widget.idle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var mediumView: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 9)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        AngularGradient(colors: [.accentColor, .green], center: .center),
                        style: StrokeStyle(lineWidth: 9, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                Text("\(Int(progress * 100))%")
                    .font(.headline.bold())
                    .monospacedDigit()
            }
            .frame(width: 80, height: 80)

            VStack(alignment: .leading, spacing: 6) {
                Text(entry.snapshot.planName)
                    .font(.headline)
                if entry.snapshot.isFasting {
                    Label {
                        Text(timerInterval: entry.snapshot.startTime...entry.snapshot.targetEndTime, countsDown: false)
                            .monospacedDigit()
                    } icon: {
                        Image(systemName: "timer")
                    }
                    .font(.subheadline)
                    Text(entry.snapshot.targetEndTime, style: .time)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("widget.idle.full")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
    }

    private var accessoryView: some View {
        Gauge(value: progress) {
            Image(systemName: "timer")
        }
        .gaugeStyle(.accessoryCircularCapacity)
    }
}

#Preview(as: .systemSmall) {
    FastingProgressWidget()
} timeline: {
    FastingEntry(date: .now, snapshot: FastingSnapshot(
        isFasting: true,
        startTime: .now.addingTimeInterval(-10 * 3600),
        targetEndTime: .now.addingTimeInterval(6 * 3600),
        planName: "16:8"
    ))
    FastingEntry(date: .now, snapshot: .idle)
}
