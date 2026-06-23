//
//  EntryCard.swift
//  OneWord
//
//  Compact card showing one entry: emoji, text, optional photo thumbnail,
//  mood tags, and a sentiment color accent.
//

import SwiftUI

struct EntryCard: View {
    let entry: DiaryEntry

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.md) {
            // Sentiment-colored emoji disc.
            Text(entry.emoji)
                .font(.system(size: 28))
                .frame(width: 48, height: 48)
                .background(Circle().fill(entry.sentiment.color.opacity(0.18)))

            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(entry.date.mediumString)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(entry.text)
                    .font(.body)
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(3)

                if !entry.moodTags.isEmpty {
                    TagRow(tags: entry.moodTags)
                }
            }

            Spacer(minLength: 0)

            if let data = entry.photoData, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous))
                    .accessibilityHidden(true)
            }
        }
        .cardStyle()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(verbatim: "\(entry.date.mediumString), \(entry.sentiment.localizedTitle). \(entry.text)"))
    }
}

/// Wrapping row of small tag chips.
struct TagRow: View {
    let tags: [String]

    var body: some View {
        HStack(spacing: Theme.Spacing.xs) {
            ForEach(tags.prefix(3), id: \.self) { tag in
                Text(LocalizedStringKey(tag))
                    .font(.caption2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Theme.accent.opacity(0.12)))
                    .foregroundStyle(Theme.accent)
            }
        }
    }
}

#Preview {
    EntryCard(entry: PreviewData.sampleEntry)
        .padding()
        .background(Theme.background)
}
