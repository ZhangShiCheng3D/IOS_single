//
//  SentimentAnalyzer.swift
//  OneWord
//
//  100% on-device emotion analysis built on Apple's NaturalLanguage
//  framework. Nothing here touches the network — every score, keyword,
//  and tag is computed locally. This file is the privacy core of OneWord.
//

import Foundation
import NaturalLanguage

/// A single, reusable analyzer. The underlying NLTagger objects are cheap to
/// recreate, so this type is stateless and safe to call from any context.
struct SentimentAnalyzer {

    /// Result of analyzing one diary entry's text.
    struct Analysis {
        var sentimentScore: Double
        var keywords: [String]
        var suggestedTags: [String]
    }

    /// Analyzes `text`, optionally blending in a prior from the chosen emoji
    /// so very short entries still get a sensible reading.
    ///
    /// - Parameters:
    ///   - text: The user's single line of journal text.
    ///   - emojiBaseline: Sentiment prior implied by the selected emoji.
    /// - Returns: Sentiment score, extracted keywords, and suggested tags.
    func analyze(text: String, emojiBaseline: Double = 0) -> Analysis {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        let textScore = trimmed.isEmpty ? nil : sentimentScore(for: trimmed)
        let blended = blend(textScore: textScore, emojiBaseline: emojiBaseline)

        let keywords = extractKeywords(from: trimmed)
        let tags = suggestTags(score: blended, keywords: keywords)

        return Analysis(
            sentimentScore: blended,
            keywords: keywords,
            suggestedTags: tags
        )
    }

    // MARK: - Sentiment

    /// Raw sentiment in [-1, 1] from the `.sentimentScore` tag scheme.
    func sentimentScore(for text: String) -> Double? {
        let tagger = NLTagger(tagSchemes: [.sentimentScore])
        tagger.string = text

        let (tag, _) = tagger.tag(
            at: text.startIndex,
            unit: .paragraph,
            scheme: .sentimentScore
        )

        guard let value = tag?.rawValue, let score = Double(value) else {
            return nil
        }
        return score
    }

    /// Blends a text-derived score with the emoji prior. When text is missing
    /// we fall back entirely to the emoji; otherwise the text dominates.
    private func blend(textScore: Double?, emojiBaseline: Double) -> Double {
        switch textScore {
        case let .some(score) where score != 0:
            // Text carries signal — weight it heavily, nudge with the emoji.
            return clamp(score * 0.8 + emojiBaseline * 0.2)
        case .some:
            // NL returned an exact 0 (neutral / unsupported) — lean on emoji.
            return clamp(emojiBaseline * 0.6)
        case .none:
            return clamp(emojiBaseline)
        }
    }

    private func clamp(_ value: Double) -> Double {
        min(1, max(-1, value))
    }

    // MARK: - Keyword extraction

    /// Extracts up to `limit` salient terms (nouns, verbs, proper nouns)
    /// using lexical-class tagging and lemmatization.
    func extractKeywords(from text: String, limit: Int = 5) -> [String] {
        guard !text.isEmpty else { return [] }

        let tagger = NLTagger(tagSchemes: [.lexicalClass, .lemma])
        tagger.string = text

        let options: NLTagger.Options = [
            .omitWhitespace, .omitPunctuation, .omitOther, .joinNames
        ]
        let wanted: Set<NLTag> = [.noun, .verb, .otherWord]

        var seen = Set<String>()
        var keywords: [String] = []

        tagger.enumerateTags(
            in: text.startIndex..<text.endIndex,
            unit: .word,
            scheme: .lexicalClass,
            options: options
        ) { tag, range in
            guard let tag, wanted.contains(tag) else { return true }

            let surface = String(text[range])
            // Skip very short tokens (particles, single CJK function chars are
            // rare but cheap to guard against).
            guard surface.count >= 2 || isCJK(surface) else { return true }

            // Prefer the lemma when available for cleaner tags.
            let (lemmaTag, _) = tagger.tag(
                at: range.lowerBound,
                unit: .word,
                scheme: .lemma
            )
            let word = (lemmaTag?.rawValue ?? surface).lowercased()

            if seen.insert(word).inserted {
                keywords.append(word)
            }
            return keywords.count < limit
        }

        return keywords
    }

    /// Detects whether a token contains CJK characters (so short Chinese
    /// words aren't discarded by the length filter).
    private func isCJK(_ s: String) -> Bool {
        s.unicodeScalars.contains { (0x4E00...0x9FFF).contains($0.value) }
    }

    // MARK: - Tag suggestion

    /// Suggests mood tags by combining the sentiment bucket with any keywords
    /// that match a small, on-device emotional lexicon.
    func suggestTags(score: Double, keywords: [String]) -> [String] {
        var tags: [String] = []

        // 1. A tag for the overall sentiment bucket.
        tags.append(Sentiment(score: score).rawValue)

        // 2. Lexicon hits among the extracted keywords.
        for keyword in keywords {
            if let theme = Self.lexicon.first(where: { $0.value.contains(keyword) })?.key {
                if !tags.contains(theme) {
                    tags.append(theme)
                }
            }
        }

        return Array(tags.prefix(4))
    }

    /// A tiny, multilingual theme lexicon. Intentionally small and local — this
    /// is a hint generator, not a classifier, and ships with the app. Covers the
    /// six shipping locales (en / zh / es / ja / de / fr) so non-English users
    /// also get theme tags.
    static let lexicon: [String: Set<String>] = [
        "tag.work":    ["work", "job", "office", "meeting", "deadline",          // en
                        "工作", "加班", "会议",                                    // zh
                        "trabajo", "oficina", "reunión",                          // es
                        "仕事", "会議", "残業",                                    // ja
                        "arbeit", "büro", "termin",                               // de
                        "travail", "bureau", "réunion"],                          // fr
        "tag.family":  ["family", "mom", "dad", "home", "kid",
                        "家", "家人", "妈妈", "爸爸",
                        "familia", "mamá", "papá", "casa",
                        "家族", "母", "父",
                        "familie", "mama", "papa", "zuhause",
                        "famille", "maman", "papa", "maison"],
        "tag.friends": ["friend", "party", "hang",
                        "朋友", "聚会",
                        "amigo", "amigos", "fiesta",
                        "友達", "友人",
                        "freund", "freunde",
                        "ami", "amis", "fête"],
        "tag.health":  ["sleep", "tired", "run", "gym", "sick",
                        "睡", "累", "运动", "病",
                        "dormir", "cansado", "gimnasio", "enfermo",
                        "睡眠", "疲れ", "運動", "病気",
                        "schlaf", "müde", "sport", "krank",
                        "sommeil", "fatigué", "malade"],
        "tag.love":    ["love", "miss", "date",
                        "爱", "想念", "约会",
                        "amor", "amar", "cita",
                        "愛", "恋", "デート",
                        "liebe", "lieben",
                        "amour", "aimer"],
        "tag.weather": ["rain", "sun", "snow",
                        "雨", "晴", "雪", "天气",
                        "lluvia", "sol", "nieve",
                        "晴れ", "雪", "天気",
                        "regen", "sonne", "schnee", "wetter",
                        "pluie", "soleil", "neige", "météo"],
        "tag.food":    ["eat", "food", "coffee", "dinner",
                        "吃", "咖啡", "饭",
                        "comer", "comida", "café", "cena",
                        "食事", "ご飯", "コーヒー",
                        "essen", "kaffee", "abendessen",
                        "manger", "nourriture", "dîner"]
    ]
}
