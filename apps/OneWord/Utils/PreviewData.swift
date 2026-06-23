//
//  PreviewData.swift
//  OneWord
//
//  In-memory SwiftData container seeded with sample entries for SwiftUI
//  previews. Not used in production builds.
//

import Foundation
import SwiftData

enum PreviewData {

    /// An in-memory container pre-populated with a month of sample entries.
    @MainActor
    static let container: ModelContainer = {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: DiaryEntry.self, configurations: config)

        let samples: [(String, String, Double, [String])] = [
            ("今天阳光很好，心情也跟着亮了起来。", "😄", 0.8, ["sentiment.veryPositive", "tag.weather"]),
            ("Quiet coffee, finished a good book.", "😌", 0.4, ["sentiment.positive", "tag.food"]),
            ("加班到很晚，有点累。", "😴", -0.3, ["sentiment.negative", "tag.work"]),
            ("和老朋友聊了很久，很温暖。", "🤗", 0.6, ["sentiment.veryPositive", "tag.friends"]),
            ("下雨了，懒洋洋的一天。", "😐", 0.0, ["sentiment.neutral", "tag.weather"]),
            ("Missed the deadline. Frustrating day.", "😡", -0.7, ["sentiment.veryNegative", "tag.work"]),
            ("Long run by the river — felt alive.", "😄", 0.7, ["sentiment.veryPositive", "tag.health"])
        ]

        let context = container.mainContext
        for (offset, sample) in samples.enumerated() {
            let entry = DiaryEntry(
                text: sample.0,
                emoji: sample.1,
                date: Calendar.current.date(byAdding: .day, value: -offset, to: Date())!,
                sentimentScore: sample.2,
                keywords: ["sample", "mood"],
                moodTags: sample.3
            )
            context.insert(entry)
        }
        return container
    }()

    /// A single sample entry for component previews.
    @MainActor
    static var sampleEntry: DiaryEntry {
        DiaryEntry(
            text: "今天阳光很好，心情也跟着亮了起来。",
            emoji: "😄",
            date: Date(),
            sentimentScore: 0.8,
            keywords: ["阳光", "心情"],
            moodTags: ["sentiment.veryPositive", "tag.weather"]
        )
    }
}
