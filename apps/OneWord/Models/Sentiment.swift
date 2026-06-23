//
//  Sentiment.swift
//  OneWord
//
//  Coarse sentiment buckets derived from the NaturalLanguage sentiment
//  score. Used for coloring, filtering, and insight summaries.
//

import SwiftUI

enum Sentiment: String, CaseIterable, Identifiable, Codable {
    case veryPositive
    case positive
    case neutral
    case negative
    case veryNegative

    var id: String { rawValue }

    /// Buckets a raw [-1, 1] score into a category.
    init(score: Double) {
        switch score {
        case 0.5...:        self = .veryPositive
        case 0.1..<0.5:     self = .positive
        case -0.1..<0.1:    self = .neutral
        case -0.5 ..< -0.1: self = .negative
        default:            self = .veryNegative
        }
    }

    /// Localized display name.
    var title: LocalizedStringKey {
        switch self {
        case .veryPositive: return "sentiment.veryPositive"
        case .positive:     return "sentiment.positive"
        case .neutral:      return "sentiment.neutral"
        case .negative:     return "sentiment.negative"
        case .veryNegative: return "sentiment.veryNegative"
        }
    }

    /// Resolved display name as a plain `String`, for composing VoiceOver labels.
    var localizedTitle: String {
        String(localized: String.LocalizationValue("sentiment.\(rawValue)"))
    }

    /// A representative emoji for the bucket (used as a fallback glyph).
    var glyph: String {
        switch self {
        case .veryPositive: return "😄"
        case .positive:     return "🙂"
        case .neutral:      return "😐"
        case .negative:     return "😕"
        case .veryNegative: return "😢"
        }
    }

    /// Color used across charts, calendar, and cards.
    var color: Color {
        switch self {
        case .veryPositive: return Color("MoodVeryPositive")
        case .positive:     return Color("MoodPositive")
        case .neutral:      return Color("MoodNeutral")
        case .negative:     return Color("MoodNegative")
        case .veryNegative: return Color("MoodVeryNegative")
        }
    }

    /// Numeric value for plotting on a -2...2 axis.
    var plotValue: Double {
        switch self {
        case .veryPositive: return 2
        case .positive:     return 1
        case .neutral:      return 0
        case .negative:     return -1
        case .veryNegative: return -2
        }
    }
}
