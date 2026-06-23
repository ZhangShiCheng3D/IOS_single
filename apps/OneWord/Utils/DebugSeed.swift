//
//  DebugSeed.swift
//  OneWord
//
//  TEST-ONLY sample data tools, compiled out of release builds. Lets the
//  insight suite (trends / year review / year-in-pixels) be exercised on the
//  simulator without hand-entering a year of entries.
//

#if DEBUG
import Foundation
import SwiftData

enum DebugSeed {

    /// Seeds ~10 months of varied entries (skipping ~30% of days for a
    /// realistic streak pattern). Skips days that already have an entry.
    @MainActor
    static func seed(into context: ModelContext, existing: [DiaryEntry]) {
        let templates: [(String, String, Double, [String])] = [
            ("Sunny morning, good coffee.", "😄", 0.8, ["sentiment.veryPositive", "tag.food"]),
            ("Quiet, productive day at work.", "🙂", 0.4, ["sentiment.positive", "tag.work"]),
            ("Long meeting, a bit drained.", "😴", -0.2, ["sentiment.negative", "tag.work"]),
            ("Dinner with old friends.", "🤗", 0.6, ["sentiment.veryPositive", "tag.friends"]),
            ("Rainy and slow.", "😐", 0.0, ["sentiment.neutral", "tag.weather"]),
            ("Missed a deadline. Rough day.", "😡", -0.7, ["sentiment.veryNegative", "tag.work"]),
            ("Great run by the river.", "😄", 0.7, ["sentiment.veryPositive", "tag.health"]),
            ("Missing someone today.", "😢", -0.5, ["sentiment.negative", "tag.love"]),
            ("Cooked something new tonight.", "😌", 0.3, ["sentiment.positive", "tag.food"]),
            ("Slept badly, tired all day.", "😕", -0.3, ["sentiment.negative", "tag.health"])
        ]
        let existingDays = Set(existing.map(\.date))
        let cal = Calendar.current
        for dayOffset in 0..<330 {
            if dayOffset % 10 == 3 || dayOffset % 7 == 5 { continue }
            guard let date = cal.date(byAdding: .day, value: -dayOffset, to: Date()) else { continue }
            if existingDays.contains(date.startOfDay) { continue }
            let t = templates[(dayOffset * 7) % templates.count]
            context.insert(DiaryEntry(
                text: t.0, emoji: t.1, date: date,
                sentimentScore: t.2, keywords: ["sample"], moodTags: t.3
            ))
        }
        try? context.save()
    }

    @MainActor
    static func clear(_ entries: [DiaryEntry], in context: ModelContext) {
        for entry in entries { context.delete(entry) }
        try? context.save()
    }
}
#endif
