//
//  EntryDetailView.swift
//  OneWord
//
//  Full-screen read view for a single entry, with edit and delete actions.
//

import SwiftUI
import SwiftData

struct EntryDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let entry: DiaryEntry

    @State private var showingEditor = false
    @State private var showingDeleteAlert = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                header

                if let data = entry.photoData, let image = UIImage(data: data) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
                        .accessibilityLabel("a11y.photo")
                }

                Text(entry.text)
                    .font(.title3)
                    .foregroundStyle(Theme.textPrimary)

                sentimentCard

                if !entry.keywords.isEmpty {
                    keywordsCard
                }
            }
            .padding(Theme.Spacing.lg)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle(entry.date.mediumString)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("common.edit", systemImage: "pencil") {
                        showingEditor = true
                    }
                    Button("common.delete", systemImage: "trash", role: .destructive) {
                        showingDeleteAlert = true
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingEditor) {
            EntryEditorView(date: entry.date, existing: entry)
        }
        .alert("detail.deleteTitle", isPresented: $showingDeleteAlert) {
            Button("common.cancel", role: .cancel) {}
            Button("common.delete", role: .destructive) {
                context.delete(entry)
                try? context.save()
                Haptics.success()
                dismiss()
            }
        } message: {
            Text("detail.deleteMessage")
        }
    }

    private var header: some View {
        HStack(spacing: Theme.Spacing.md) {
            Text(entry.emoji)
                .font(.system(size: 44))
                .frame(width: 72, height: 72)
                .background(Circle().fill(entry.sentiment.color.opacity(0.18)))
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.date.weekdayString)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(entry.sentiment.title)
                    .font(.title3.bold())
                    .foregroundStyle(entry.sentiment.color)
            }
            Spacer()
        }
    }

    private var sentimentCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Label("detail.moodAnalysis", systemImage: "sparkles")
                .font(.headline)
                .foregroundStyle(Theme.accent)
            if !entry.moodTags.isEmpty {
                TagRow(tags: entry.moodTags)
            }
            Text("editor.onDeviceNote")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private var keywordsCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Label("detail.keywords", systemImage: "tag")
                .font(.headline)
            HStack {
                ForEach(entry.keywords.prefix(5), id: \.self) { word in
                    Text(word)
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Theme.card))
                        .overlay(Capsule().strokeBorder(Theme.accent.opacity(0.3)))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}

#Preview {
    NavigationStack {
        EntryDetailView(entry: PreviewData.sampleEntry)
    }
    .modelContainer(PreviewData.container)
}
