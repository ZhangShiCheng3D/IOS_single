//
//  DocumentRowView.swift
//  DocScanPro
//
//  文档列表单元格：缩略图 + 标题 + 元信息 + 标签。
//

import SwiftUI

struct DocumentRowView: View {
    let document: ScanDocument

    var body: some View {
        HStack(spacing: 14) {
            thumbnail
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 6) {
                    if document.isFavorite {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundStyle(.yellow)
                    }
                    Text(document.title)
                        .font(.headline)
                        .lineLimit(1)
                }

                HStack(spacing: 8) {
                    Label("\(document.pageCount)", systemImage: "doc.on.doc")
                    if document.hasRecognizedText {
                        Label("documents.row.ocr", systemImage: "text.viewfinder")
                            .foregroundStyle(Color.accentColor)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                Text(document.updatedAt.documentListDisplay)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)

                if !document.tags.isEmpty {
                    tagChips
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, DS.Spacing.xxs)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
    }

    /// 为 VoiceOver 组合一段简洁的描述：标题 + 页数 + 是否已识别 + 收藏。
    private var accessibilityDescription: Text {
        var parts: [String] = [document.title]
        parts.append(String(format: NSLocalizedString("a11y.row.pages", comment: ""), document.pageCount))
        if document.hasRecognizedText {
            parts.append(NSLocalizedString("a11y.row.hasText", comment: ""))
        }
        if document.isFavorite {
            parts.append(NSLocalizedString("a11y.row.favorite", comment: ""))
        }
        return Text(parts.joined(separator: ", "))
    }

    private var thumbnail: some View {
        Group {
            if let data = document.thumbnailData, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    Color(.secondarySystemBackground)
                    Image(systemName: "doc.text")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(width: 54, height: 70)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.sm, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.sm, style: .continuous)
                .stroke(Color(.separator), lineWidth: 0.5)
        )
        .accessibilityHidden(true)
    }

    private var tagChips: some View {
        HStack(spacing: 6) {
            ForEach(document.tags.prefix(3)) { tag in
                Text(tag.name)
                    .font(.caption2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(tag.color.opacity(0.18), in: Capsule())
                    .foregroundStyle(tag.color)
            }
        }
    }
}

#Preview {
    List {
        DocumentRowView(document: PreviewData.sampleDocument)
    }
    .modelContainer(PreviewData.container)
}
