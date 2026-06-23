//
//  EntryEditorViewModel.swift
//  OneWord
//
//  Drives the daily entry editor: holds the draft, runs on-device analysis,
//  and persists to SwiftData. One entry per calendar day — editing today
//  updates the existing entry rather than creating duplicates.
//

import Foundation
import SwiftData
import SwiftUI
import Observation

@Observable
final class EntryEditorViewModel {

    /// Hard cap on the single line of text, keeping the "one word" spirit.
    static let characterLimit = 140

    var text: String = ""
    var emoji: String = "🙂"
    var photoData: Data?

    /// Live analysis preview shown beneath the editor.
    private(set) var previewScore: Double = 0
    private(set) var suggestedTags: [String] = []

    /// The day being edited.
    let date: Date

    /// The existing entry for this day, if any.
    private var existing: DiaryEntry?

    private let analyzer = SentimentAnalyzer()

    init(date: Date = Date(), existing: DiaryEntry? = nil) {
        self.date = date.startOfDay
        self.existing = existing
        if let existing {
            self.text = existing.text
            self.emoji = existing.emoji
            self.photoData = existing.photoData
            self.previewScore = existing.sentimentScore
            self.suggestedTags = existing.moodTags
        }
    }

    var remainingCharacters: Int {
        Self.characterLimit - text.count
    }

    var canSave: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var sentiment: Sentiment {
        Sentiment(score: previewScore)
    }

    /// Recomputes the live sentiment preview as the user types or picks an emoji.
    func updatePreview() {
        let analysis = analyzer.analyze(
            text: text,
            emojiBaseline: MoodEmoji.baseline(for: emoji)
        )
        previewScore = analysis.sentimentScore
        suggestedTags = analysis.suggestedTags
    }

    /// Persists the draft, creating or updating the day's entry.
    /// - Returns: `true` on success.
    @discardableResult
    func save(in context: ModelContext) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }

        let analysis = analyzer.analyze(
            text: trimmed,
            emojiBaseline: MoodEmoji.baseline(for: emoji)
        )

        if let entry = existing {
            entry.text = trimmed
            entry.emoji = emoji
            entry.photoData = photoData
            entry.sentimentScore = analysis.sentimentScore
            entry.keywords = analysis.keywords
            entry.moodTags = analysis.suggestedTags
            entry.updatedAt = Date()
        } else {
            let entry = DiaryEntry(
                text: trimmed,
                emoji: emoji,
                photoData: photoData,
                date: date,
                sentimentScore: analysis.sentimentScore,
                keywords: analysis.keywords,
                moodTags: analysis.suggestedTags
            )
            context.insert(entry)
            existing = entry
        }

        do {
            try context.save()
            return true
        } catch {
            return false
        }
    }
}
