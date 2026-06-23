//
//  OneWordWidget.swift
//  OneWordWidget extension
//
//  Home- and lock-screen widgets showing the current streak and whether today
//  has been logged, reading the shared snapshot the app maintains. Tapping
//  deep-links into today's editor.
//

import WidgetKit
import SwiftUI

struct OneWordTimelineEntry: TimelineEntry {
    let date: Date
    let snapshot: OneWordShared.Snapshot
}

struct OneWordProvider: TimelineProvider {
    func placeholder(in context: Context) -> OneWordTimelineEntry {
        OneWordTimelineEntry(date: Date(), snapshot: .init(streak: 7, todayLogged: false, total: 128))
    }

    func getSnapshot(in context: Context, completion: @escaping (OneWordTimelineEntry) -> Void) {
        completion(OneWordTimelineEntry(date: Date(), snapshot: OneWordShared.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<OneWordTimelineEntry>) -> Void) {
        let entry = OneWordTimelineEntry(date: Date(), snapshot: OneWordShared.load())
        // Refresh at the next local midnight so "today logged" resets.
        let next = Calendar.current.nextDate(
            after: Date(),
            matching: DateComponents(hour: 0, minute: 1),
            matchingPolicy: .nextTime
        ) ?? Date().addingTimeInterval(3600)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

struct OneWordWidgetView: View {
    @Environment(\.widgetFamily) private var family
    var entry: OneWordTimelineEntry

    var body: some View {
        switch family {
        case .systemMedium: medium
        default: small
        }
    }

    private var small: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: "flame.fill").foregroundStyle(.orange)
                Text("\(entry.snapshot.streak)").font(.system(size: 34, weight: .bold))
            }
            Text("day streak").font(.caption).foregroundStyle(.secondary)
            Spacer()
            statusLine
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .containerBackground(.fill.tertiary, for: .widget)
        .widgetURL(OneWordShared.recordURL)
    }

    private var medium: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill").foregroundStyle(.orange)
                    Text("\(entry.snapshot.streak)").font(.system(size: 40, weight: .bold))
                }
                Text("day streak").font(.caption).foregroundStyle(.secondary)
            }
            Divider()
            VStack(alignment: .leading, spacing: 6) {
                Text("OneWord").font(.headline)
                statusLine
                Text("\(entry.snapshot.total) entries").font(.caption2).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .containerBackground(.fill.tertiary, for: .widget)
        .widgetURL(OneWordShared.recordURL)
    }

    @ViewBuilder
    private var statusLine: some View {
        if entry.snapshot.todayLogged {
            Label("Logged today", systemImage: "checkmark.circle.fill")
                .font(.caption).foregroundStyle(.green)
        } else {
            Label("Tap to write today", systemImage: "square.and.pencil")
                .font(.caption).foregroundStyle(.primary)
        }
    }
}

struct OneWordWidget: Widget {
    let kind = "OneWordWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: OneWordProvider()) { entry in
            OneWordWidgetView(entry: entry)
        }
        .configurationDisplayName("OneWord")
        .description("Your current streak and today's status, one tap from writing.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct OneWordWidgetBundle: WidgetBundle {
    var body: some Widget {
        OneWordWidget()
    }
}
