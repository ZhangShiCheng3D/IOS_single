//
//  TodayView.swift
//  OneWord
//
//  Home screen. Prompts the user to record today's word if they haven't,
//  shows today's entry if they have, plus a streak banner and recent history.
//

import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \DiaryEntry.date, order: .reverse) private var entries: [DiaryEntry]

    @State private var showingEditor = false

    private let insights = InsightsViewModel()

    /// Today's entry, if it exists.
    private var todayEntry: DiaryEntry? {
        entries.first { $0.date.isSameDay(as: Date()) }
    }

    /// Entries other than today's, most recent first.
    private var history: [DiaryEntry] {
        entries.filter { !$0.date.isSameDay(as: Date()) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    streakBanner
                    todaySection
                    if !history.isEmpty {
                        historySection
                    }
                }
                .padding(Theme.Spacing.lg)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("app.name")
            .sheet(isPresented: $showingEditor) {
                EntryEditorView(date: Date(), existing: todayEntry)
            }
            .onAppear { WidgetSync.update(entries: entries) }
            .onChange(of: entries.count) { _, _ in
                WidgetSync.update(entries: entries)
            }
        }
    }

    // MARK: Sections

    private var streakBanner: some View {
        let current = insights.currentStreak(from: entries)
        return HStack(spacing: Theme.Spacing.md) {
            Image(systemName: "flame.fill")
                .font(.title)
                .foregroundStyle(.orange)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text("today.streakTitle")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("\(current)")
                    .font(.title.bold())
                + Text(" ") + Text("today.days").font(.subheadline)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(entries.count)")
                    .font(.title2.bold())
                    .foregroundStyle(Theme.accent)
                Text("today.entriesTotal")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .cardStyle()
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var todaySection: some View {
        if let entry = todayEntry {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Text("today.recorded")
                    .font(.headline)
                Button {
                    showingEditor = true
                } label: {
                    EntryCard(entry: entry)
                }
                .buttonStyle(.plain)
            }
        } else {
            VStack(spacing: Theme.Spacing.md) {
                Text("✍️").font(.system(size: 44))
                Text("today.prompt")
                    .font(.title3.bold())
                    .multilineTextAlignment(.center)
                Text("today.promptSubtitle")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Button("today.recordButton") {
                    showingEditor = true
                }
                .buttonStyle(PrimaryButtonStyle())
            }
            .frame(maxWidth: .infinity)
            .padding(Theme.Spacing.lg)
            .cardStyle()
        }
    }

    private var historySection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("today.recent")
                .font(.headline)
            ForEach(history.prefix(10)) { entry in
                NavigationLink {
                    EntryDetailView(entry: entry)
                } label: {
                    EntryCard(entry: entry)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

#Preview {
    TodayView()
        .modelContainer(PreviewData.container)
}
