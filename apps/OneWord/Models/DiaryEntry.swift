//
//  DiaryEntry.swift
//  OneWord
//
//  SwiftData model for a single day's micro-journal entry:
//  one sentence + one emoji + one optional photo, plus the on-device
//  NLP-derived sentiment and keywords.
//

import Foundation
import SwiftData

@Model
final class DiaryEntry {

    // NOTE: For optional CloudKit (iCloud) sync, every stored property must be
    // optional or carry a default value, and `.unique` constraints are not
    // allowed. `id` stays a generated UUID (collisions are impossible in
    // practice); one-entry-per-day is enforced by the editor's save logic.

    /// Stable identifier, useful for export and de-duplication.
    var id: UUID = UUID()

    /// The single line of text the user wrote. Limited in the editor.
    var text: String = ""

    /// The chosen mood emoji (e.g. "😊"). Always a single grapheme.
    var emoji: String = "🙂"

    /// Optional photo, stored externally to keep the SQLite store small.
    @Attribute(.externalStorage) var photoData: Data?

    /// The calendar day this entry belongs to, normalized to local midnight.
    var date: Date = Date()

    /// Raw sentiment score in [-1, 1] from NaturalLanguage's sentiment tagger.
    var sentimentScore: Double = 0

    /// Auto-extracted keywords (nouns / salient terms) for tags & insights.
    var keywords: [String] = []

    /// Auto-suggested mood tags the user accepted or that were inferred.
    var moodTags: [String] = []

    /// When the entry was first created.
    var createdAt: Date = Date()

    /// Last time the entry was edited.
    var updatedAt: Date = Date()

    init(
        id: UUID = UUID(),
        text: String,
        emoji: String,
        photoData: Data? = nil,
        date: Date = Date(),
        sentimentScore: Double = 0,
        keywords: [String] = [],
        moodTags: [String] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.text = text
        self.emoji = emoji
        self.photoData = photoData
        self.date = Calendar.current.startOfDay(for: date)
        self.sentimentScore = sentimentScore
        self.keywords = keywords
        self.moodTags = moodTags
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Derived helpers

extension DiaryEntry {

    /// Maps the raw sentiment score onto a coarse, user-facing category.
    var sentiment: Sentiment {
        Sentiment(score: sentimentScore)
    }

    /// Whether this entry has a photo attached.
    var hasPhoto: Bool {
        photoData != nil
    }
}
