//
//  YearReviewView.swift
//  OneWord
//
//  Auto-generated year-in-review: a narrative summary, the year's mood
//  distribution, standout days, and recurring themes — all computed on-device.
//

import SwiftUI
import SwiftData
import Charts

struct YearReviewView: View {
    @Query(sort: \DiaryEntry.date) private var entries: [DiaryEntry]

    @State private var year: Int = Calendar.current.component(.year, from: Date())

    private let insights = InsightsViewModel()

    private var yearEntries: [DiaryEntry] {
        entries.filter { Calendar.current.component(.year, from: $0.date) == year }
    }

    /// Distinct years that have entries, for the picker.
    private var availableYears: [Int] {
        let years = Set(entries.map { Calendar.current.component(.year, from: $0.date) })
        return years.sorted(by: >)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                yearPicker
                if yearEntries.isEmpty {
                    emptyState
                } else {
                    narrativeCard
                    YearInPixelsView(entries: yearEntries, year: year)
                    distributionCard
                    standoutCard
                }
            }
            .padding(Theme.Spacing.lg)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("year.title")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private var yearPicker: some View {
        if availableYears.count > 1 {
            Picker("year.select", selection: $year) {
                ForEach(availableYears, id: \.self) { y in
                    Text(String(y)).tag(y)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var narrativeCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack {
                Image(systemName: "sparkles")
                Text("year.yourYear")
            }
            .font(.headline)
            .foregroundStyle(Theme.accent)

            Text(insights.yearReviewNarrative(for: yearEntries, year: year))
                .font(.body)
                .foregroundStyle(Theme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private var distributionCard: some View {
        let counts = Dictionary(grouping: yearEntries) { $0.sentiment }
            .mapValues(\.count)
        let data = Sentiment.allCases.map { (sentiment: $0, count: counts[$0] ?? 0) }

        return VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("year.distribution")
                .font(.headline)
            Chart(data, id: \.sentiment) { item in
                BarMark(
                    x: .value("Mood", item.sentiment.glyph),
                    y: .value("Count", item.count)
                )
                .foregroundStyle(item.sentiment.color)
                .cornerRadius(6)
            }
            .frame(height: 200)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private var standoutCard: some View {
        let happiest = yearEntries.max { $0.sentimentScore < $1.sentimentScore }
        let toughest = yearEntries.min { $0.sentimentScore < $1.sentimentScore }

        return VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("year.standout")
                .font(.headline)
            if let happiest {
                standoutRow(title: "year.brightest", entry: happiest)
            }
            if let toughest, toughest.id != happiest?.id {
                standoutRow(title: "year.toughest", entry: toughest)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private func standoutRow(title: LocalizedStringKey, entry: DiaryEntry) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(spacing: Theme.Spacing.sm) {
                Text(entry.emoji).font(.title2)
                VStack(alignment: .leading) {
                    Text(entry.text).font(.subheadline).lineLimit(2)
                    Text(entry.date.mediumString)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Text("🗓️").font(.system(size: 40))
            Text("year.empty").font(.headline)
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.Spacing.xl)
        .cardStyle()
    }
}

#Preview {
    NavigationStack {
        YearReviewView()
    }
    .modelContainer(PreviewData.container)
}
