//
//  PageTextEditor.swift
//  DocScanPro
//
//  单页 OCR 文本编辑器：可查看、复制、编辑识别文本。
//

import SwiftUI

struct PageTextEditor: View {

    @Bindable var page: ScannedPage
    let document: ScanDocument
    /// 文本变更保存回调。
    var onSave: (String) -> Void

    @State private var draft: String = ""
    @State private var isEditing = false
    @State private var didCopy = false
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()
            content
        }
        .onAppear { draft = page.recognizedText }
        .onChange(of: page.id) { _, _ in
            draft = page.recognizedText
            isEditing = false
        }
    }

    private var header: some View {
        HStack {
            Text("detail.text.title")
                .font(.subheadline.bold())
                .foregroundStyle(.secondary)
            Spacer()
            if isEditing {
                Button("common.done") {
                    onSave(draft)
                    isEditing = false
                    isFocused = false
                }
                .font(.subheadline.bold())
            } else if !page.recognizedText.isEmpty {
                Button {
                    UIPasteboard.general.string = page.recognizedText
                    Haptics.tapLight()
                    withAnimation { didCopy = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
                        withAnimation { didCopy = false }
                    }
                } label: {
                    // 显式声明为 LocalizedStringKey，避免三元字面量退化为不本地化的 String。
                    let copyKey: LocalizedStringKey = didCopy ? "detail.text.copied" : "detail.text.copy"
                    Label(copyKey, systemImage: didCopy ? "checkmark" : "doc.on.doc")
                        .font(.subheadline)
                }
                Button {
                    isEditing = true
                    isFocused = true
                } label: {
                    Image(systemName: "pencil")
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private var content: some View {
        Group {
            if page.recognizedText.isEmpty && !isEditing {
                VStack(spacing: 10) {
                    Image(systemName: "text.badge.xmark")
                        .font(.title)
                        .foregroundStyle(.secondary)
                    Text("detail.text.empty")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if isEditing {
                TextEditor(text: $draft)
                    .focused($isFocused)
                    .font(.body)
                    .padding(.horizontal, 12)
                    .scrollContentBackground(.hidden)
            } else {
                ScrollView {
                    Text(page.recognizedText)
                        .font(.body)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                }
            }
        }
    }
}

#Preview {
    PageTextEditor(
        page: PreviewData.sampleDocument.orderedPages.first!,
        document: PreviewData.sampleDocument,
        onSave: { _ in }
    )
    .modelContainer(PreviewData.container)
}
