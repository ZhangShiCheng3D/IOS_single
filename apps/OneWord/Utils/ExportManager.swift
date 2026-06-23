//
//  ExportManager.swift
//  OneWord
//
//  Builds shareable exports of the journal entirely on-device. Supports a
//  human-readable Markdown digest and a machine-readable JSON backup.
//

import Foundation
import SwiftUI

enum ExportFormat: String, CaseIterable, Identifiable {
    case markdown
    case json
    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .markdown: return "export.markdown"
        case .json:     return "export.json"
        }
    }

    var fileExtension: String {
        switch self {
        case .markdown: return "md"
        case .json:     return "json"
        }
    }
}

struct ExportManager {

    /// Codable mirror of an entry for stable JSON output.
    private struct ExportEntry: Codable {
        let id: UUID
        let date: Date
        let text: String
        let emoji: String
        let sentimentScore: Double
        let keywords: [String]
        let moodTags: [String]
    }

    /// Writes the given entries to a temporary file and returns its URL.
    /// The caller is responsible for presenting a share sheet.
    func export(_ entries: [DiaryEntry], as format: ExportFormat) throws -> URL {
        let sorted = entries.sorted { $0.date < $1.date }
        let data: Data

        switch format {
        case .markdown:
            data = Data(makeMarkdown(sorted).utf8)
        case .json:
            let payload = sorted.map {
                ExportEntry(
                    id: $0.id, date: $0.date, text: $0.text, emoji: $0.emoji,
                    sentimentScore: $0.sentimentScore, keywords: $0.keywords,
                    moodTags: $0.moodTags
                )
            }
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            data = try encoder.encode(payload)
        }

        let filename = "OneWord-Export.\(format.fileExtension)"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try data.write(to: url, options: .atomic)
        return url
    }

    private func makeMarkdown(_ entries: [DiaryEntry]) -> String {
        var lines = ["# OneWord", ""]
        lines.append("_\(entries.count) " + String(localized: "export.entriesCount") + "_")
        lines.append("")

        for entry in entries {
            lines.append("## \(entry.date.mediumString)  \(entry.emoji)")
            lines.append("")
            lines.append(entry.text)
            if !entry.moodTags.isEmpty {
                let tags = entry.moodTags.map { "`\($0)`" }.joined(separator: " ")
                lines.append("")
                lines.append(tags)
            }
            lines.append("")
        }
        return lines.joined(separator: "\n")
    }
}
