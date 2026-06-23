//
//  MoodEmoji.swift
//  OneWord
//
//  The curated palette of mood emojis offered in the editor, each with a
//  baseline sentiment hint used when text is too short to analyze.
//

import Foundation

struct MoodEmoji: Identifiable, Hashable {
    var id: String { emoji }
    let emoji: String
    /// Baseline sentiment in [-1, 1] used as a prior when text is sparse.
    let baseline: Double
    /// A short localization key describing the mood.
    let nameKey: String

    static let palette: [MoodEmoji] = [
        MoodEmoji(emoji: "😄", baseline: 0.9,  nameKey: "mood.joyful"),
        MoodEmoji(emoji: "🙂", baseline: 0.5,  nameKey: "mood.good"),
        MoodEmoji(emoji: "😌", baseline: 0.4,  nameKey: "mood.calm"),
        MoodEmoji(emoji: "😍", baseline: 0.8,  nameKey: "mood.loved"),
        MoodEmoji(emoji: "🤗", baseline: 0.6,  nameKey: "mood.grateful"),
        MoodEmoji(emoji: "😐", baseline: 0.0,  nameKey: "mood.neutral"),
        MoodEmoji(emoji: "😴", baseline: 0.0,  nameKey: "mood.tired"),
        MoodEmoji(emoji: "🤔", baseline: 0.0,  nameKey: "mood.thoughtful"),
        MoodEmoji(emoji: "😕", baseline: -0.4, nameKey: "mood.uneasy"),
        MoodEmoji(emoji: "😢", baseline: -0.7, nameKey: "mood.sad"),
        MoodEmoji(emoji: "😡", baseline: -0.8, nameKey: "mood.angry"),
        MoodEmoji(emoji: "😰", baseline: -0.6, nameKey: "mood.anxious")
    ]

    /// Looks up the baseline for an emoji, defaulting to neutral.
    static func baseline(for emoji: String) -> Double {
        palette.first { $0.emoji == emoji }?.baseline ?? 0
    }
}
