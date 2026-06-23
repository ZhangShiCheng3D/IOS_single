//
//  EntryEditorView.swift
//  OneWord
//
//  The zero-pressure daily editor: one line of text, one emoji, one photo.
//  Shows a live, on-device sentiment preview and suggested mood tags.
//

import SwiftUI
import SwiftData

struct EntryEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var model: EntryEditorViewModel
    @FocusState private var textFocused: Bool

    init(date: Date = Date(), existing: DiaryEntry? = nil) {
        _model = State(initialValue: EntryEditorViewModel(date: date, existing: existing))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    dateHeader
                    textField
                    moodSection
                    PhotoPickerButton(photoData: $model.photoData) {
                        model.updatePreview()
                    }
                    sentimentPreview
                }
                .padding(Theme.Spacing.lg)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("editor.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.save") {
                        if model.save(in: context) {
                            Haptics.success()
                            dismiss()
                        }
                    }
                    .bold()
                    .disabled(!model.canSave)
                }
            }
            .onAppear {
                model.updatePreview()
                textFocused = true
            }
        }
    }

    private var dateHeader: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(model.date.weekdayString)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(model.date.mediumString)
                .font(.title2.bold())
        }
    }

    private var textField: some View {
        VStack(alignment: .trailing, spacing: Theme.Spacing.xs) {
            TextField("editor.placeholder", text: $model.text, axis: .vertical)
                .font(.title3)
                .lineLimit(3...5)
                .focused($textFocused)
                .onChange(of: model.text) { _, newValue in
                    // Enforce the character cap and refresh the live preview.
                    if newValue.count > EntryEditorViewModel.characterLimit {
                        model.text = String(newValue.prefix(EntryEditorViewModel.characterLimit))
                    }
                    model.updatePreview()
                }
                .cardStyle()

            Text("\(model.remainingCharacters)")
                .font(.caption2)
                .foregroundStyle(model.remainingCharacters < 20 ? .orange : .secondary)
        }
    }

    private var moodSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("editor.howFeeling")
                .font(.headline)
            MoodPicker(selection: $model.emoji) {
                model.updatePreview()
            }
        }
    }

    private var sentimentPreview: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(Theme.accent)
                Text("editor.aiPreview")
                    .font(.headline)
            }

            HStack(spacing: Theme.Spacing.md) {
                Text(model.sentiment.glyph)
                    .font(.system(size: 30))
                VStack(alignment: .leading, spacing: 2) {
                    Text(model.sentiment.title)
                        .font(.subheadline.bold())
                        .foregroundStyle(model.sentiment.color)
                    Text("editor.onDeviceNote")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            if !model.suggestedTags.isEmpty {
                TagRow(tags: model.suggestedTags)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}

#Preview {
    EntryEditorView()
        .modelContainer(PreviewData.container)
}
