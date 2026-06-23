//
//  TrendsView.swift
//  OneWord
//
//  Mood trend charts and summary insights. The richer AI insights (charts,
//  top tags, year review) are gated behind the one-time premium unlock; a
//  teaser + paywall is shown to free users.
//

import SwiftUI
import SwiftData
import Charts

struct TrendsView: View {
    @Environment(PurchaseManager.self) private var store
    @Query(sort: \DiaryEntry.date) private var entries: [DiaryEntry]

    @State private var range: TrendRange = .month
    @State private var showingPaywall = false

    private let insights = InsightsViewModel()

    enum TrendRange: String, CaseIterable, Identifiable {
        case week, month, year
        var id: String { rawValue }
        var title: LocalizedStringKey {
            switch self {
            case .week:  return "trends.week"
            case .month: return "trends.month"
            case .year:  return "trends.year"
            }
        }
        var days: Int {
            switch self {
            case .week:  return 7
            case .month: return 30
            case .year:  return 365
            }
        }
    }

    private var dateRange: ClosedRange<Date> {
        let end = Date().startOfDay
        let start = end.addingDays(-(range.days - 1))
        return start...end
    }

    private var rangedEntries: [DiaryEntry] {
        entries.filter { dateRange.contains($0.date) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    if store.isPremiumUnlocked {
                        unlockedContent
                    } else {
                        lockedTeaser
                    }
                }
                .padding(Theme.Spacing.lg)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("tab.trends")
            .toolbar {
                if store.isPremiumUnlocked {
                    ToolbarItem(placement: .topBarTrailing) {
                        NavigationLink {
                            YearReviewView()
                        } label: {
                            Image(systemName: "calendar.badge.clock")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
        }
    }

    // MARK: Unlocked

    @ViewBuilder
    private var unlockedContent: some View {
        Picker("trends.range", selection: $range) {
            ForEach(TrendRange.allCases) { r in
                Text(r.title).tag(r)
            }
        }
        .pickerStyle(.segmented)

        if rangedEntries.isEmpty {
            emptyState
        } else {
            chartCard
            summaryCard
            tagsCard
        }
    }

    private var chartCard: some View {
        let points = insights.trendPoints(from: entries, in: dateRange)
        return VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("trends.moodOverTime")
                .font(.headline)
            Chart(points) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Mood", point.score)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(Theme.accent)

                AreaMark(
                    x: .value("Date", point.date),
                    y: .value("Mood", point.score)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(
                    .linearGradient(
                        colors: [Theme.accent.opacity(0.3), .clear],
                        startPoint: .top, endPoint: .bottom
                    )
                )

                PointMark(
                    x: .value("Date", point.date),
                    y: .value("Mood", point.score)
                )
                .foregroundStyle(point.sentiment.color)
            }
            .chartYScale(domain: -1...1)
            .chartYAxis {
                AxisMarks(values: [-1, 0, 1])
            }
            .frame(height: 220)
        }
        .cardStyle()
    }

    private var summaryCard: some View {
        let summary = insights.summary(for: rangedEntries)
        return VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("trends.summary")
                .font(.headline)
            HStack(spacing: Theme.Spacing.lg) {
                stat(value: "\(summary.entryCount)", label: "trends.entries")
                stat(value: summary.dominantSentiment.glyph, label: "trends.dominant")
                stat(value: "\(summary.currentStreak)", label: "today.streakTitle")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private func stat(value: String, label: LocalizedStringKey) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.title2.bold()).foregroundStyle(Theme.accent)
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var tagsCard: some View {
        let tags = insights.topTags(from: rangedEntries)
        return Group {
            if tags.isEmpty {
                EmptyView()
            } else {
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    Label("trends.topThemes", systemImage: "tag")
                        .font(.headline)
                    ForEach(tags, id: \.tag) { item in
                        HStack {
                            Text(LocalizedStringKey(item.tag))
                                .font(.subheadline)
                            Spacer()
                            Text("\(item.count)")
                                .font(.subheadline.bold())
                                .foregroundStyle(Theme.accent)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .cardStyle()
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Text("📊").font(.system(size: 40))
            Text("trends.empty")
                .font(.headline)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.Spacing.xl)
        .cardStyle()
    }

    // MARK: Locked teaser

    private var lockedTeaser: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Image(systemName: "chart.xyaxis.line")
                .font(.system(size: 56))
                .foregroundStyle(Theme.accent)
            Text("trends.lockedTitle")
                .font(.title2.bold())
                .multilineTextAlignment(.center)
            Text("trends.lockedSubtitle")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("trends.unlock") {
                showingPaywall = true
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .padding(Theme.Spacing.lg)
        .cardStyle()
    }
}

#Preview("Unlocked") {
    let store = PurchaseManager()
    return TrendsView()
        .environment(store)
        .modelContainer(PreviewData.container)
}
