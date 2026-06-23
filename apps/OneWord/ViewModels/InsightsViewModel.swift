//
//  InsightsViewModel.swift
//  OneWord
//
//  Aggregates entries into the data structures the trends, calendar, and year
//  review screens render. All computation is local and synchronous over the
//  user's own (small) dataset.
//

import Foundation

struct InsightsViewModel {

    /// A single point on the mood trend line.
    struct TrendPoint: Identifiable {
        let id = UUID()
        let date: Date
        let score: Double
        var sentiment: Sentiment { Sentiment(score: score) }
    }

    /// Aggregate stats for a period (week / month / year).
    struct Summary {
        var entryCount: Int
        var averageScore: Double
        var dominantSentiment: Sentiment
        var topTags: [(tag: String, count: Int)]
        var longestStreak: Int
        var currentStreak: Int
    }

    // MARK: - Trend points

    /// Daily trend points for a date range, sorted ascending.
    func trendPoints(from entries: [DiaryEntry], in range: ClosedRange<Date>) -> [TrendPoint] {
        entries
            .filter { range.contains($0.date) }
            .sorted { $0.date < $1.date }
            .map { TrendPoint(date: $0.date, score: $0.sentimentScore) }
    }

    // MARK: - Summary

    func summary(for entries: [DiaryEntry]) -> Summary {
        guard !entries.isEmpty else {
            return Summary(
                entryCount: 0, averageScore: 0, dominantSentiment: .neutral,
                topTags: [], longestStreak: 0, currentStreak: 0
            )
        }

        let average = entries.map(\.sentimentScore).reduce(0, +) / Double(entries.count)

        // Dominant sentiment by bucket frequency.
        let buckets = Dictionary(grouping: entries) { $0.sentiment }
        let dominant = buckets.max { $0.value.count < $1.value.count }?.key ?? .neutral

        return Summary(
            entryCount: entries.count,
            averageScore: average,
            dominantSentiment: dominant,
            topTags: topTags(from: entries),
            longestStreak: longestStreak(from: entries),
            currentStreak: currentStreak(from: entries)
        )
    }

    /// Most frequent mood tags across the entries.
    func topTags(from entries: [DiaryEntry], limit: Int = 6) -> [(tag: String, count: Int)] {
        var counts: [String: Int] = [:]
        for entry in entries {
            for tag in entry.moodTags { counts[tag, default: 0] += 1 }
        }
        return counts
            .sorted { $0.value > $1.value }
            .prefix(limit)
            .map { (tag: $0.key, count: $0.value) }
    }

    // MARK: - Streaks

    /// Longest run of consecutive days with an entry.
    func longestStreak(from entries: [DiaryEntry]) -> Int {
        let days = Set(entries.map(\.date)).sorted()
        guard !days.isEmpty else { return 0 }

        var longest = 1
        var run = 1
        for i in 1..<days.count {
            if days[i] == days[i - 1].addingDays(1) {
                run += 1
                longest = max(longest, run)
            } else {
                run = 1
            }
        }
        return longest
    }

    /// Current streak counting back from today (or yesterday).
    func currentStreak(from entries: [DiaryEntry]) -> Int {
        let days = Set(entries.map(\.date))
        guard !days.isEmpty else { return 0 }

        var streak = 0
        var cursor = Date().startOfDay
        // Allow the streak to count even if today isn't logged yet.
        if !days.contains(cursor) { cursor = cursor.addingDays(-1) }

        while days.contains(cursor) {
            streak += 1
            cursor = cursor.addingDays(-1)
        }
        return streak
    }

    // MARK: - Year review

    /// A generated, human-readable year-in-review narrative (localized template).
    func yearReviewNarrative(for entries: [DiaryEntry], year: Int) -> String {
        let summary = summary(for: entries)
        guard summary.entryCount > 0 else {
            return String(localized: "year.empty")
        }

        let dominant = String(localized: String.LocalizationValue(summary.dominantSentiment.rawValueLocalized))
        let topTag = summary.topTags.first.map {
            String(localized: String.LocalizationValue($0.tag))
        } ?? "—"

        // Use string-based positional args to avoid 64-bit Int / %d pitfalls.
        let format = String(localized: "year.narrative")
        return String(
            format: format,
            String(year),
            String(summary.entryCount),
            String(summary.longestStreak),
            dominant,
            topTag
        )
    }
}

private extension Sentiment {
    /// The localization key for this sentiment's display name.
    var rawValueLocalized: String { "sentiment.\(rawValue)" }
}
