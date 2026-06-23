//
//  TextPanel.swift
//  CollageKit
//
//  文字面板：新增文字、编辑选中文字（内容、字号、粗细、颜色、旋转）、删除。
//

import SwiftUI
import SwiftData

struct TextPanel: View {
    @Bindable var project: CollageProject
    @ObservedObject var viewModel: EditorViewModel
    @Environment(\.modelContext) private var context

    private var selectedText: CollageText? {
        guard let id = viewModel.selectedTextID else { return nil }
        return project.texts.first { $0.id == id }
    }

    var body: some View {
        VStack(spacing: 14) {
            Button {
                let text = viewModel.addText(String(localized: "text_default_content"),
                                             project: project, context: context)
                viewModel.selectedTextID = text.id
            } label: {
                Label("text_add", systemImage: "plus.circle.fill")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color.accentColor.opacity(0.12))
                    .foregroundStyle(Color.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            if let text = selectedText {
                editor(for: text)
            } else {
                Text("text_select_hint")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 4)
            }
        }
    }

    @ViewBuilder
    private func editor(for text: CollageText) -> some View {
        @Bindable var text = text
        VStack(spacing: 14) {
            TextField("text_placeholder", text: $text.content, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(1...3)

            HStack {
                Text("text_size").font(.subheadline)
                Slider(value: $text.fontSize, in: 20...160, step: 1)
                    .tint(.accentColor)
            }

            Picker("text_weight", selection: weightBinding(text)) {
                ForEach(TextWeight.allCases) { w in
                    Text(weightLabel(w)).tag(w)
                }
            }
            .pickerStyle(.segmented)

            HStack(spacing: 16) {
                ColorPicker("text_color", selection: Binding(
                    get: { Color(hex: text.colorHex) },
                    set: { text.colorHex = $0.hexString; project.touch() }
                ))
                .font(.subheadline)
            }

            HStack {
                Text("text_rotation").font(.subheadline)
                Slider(value: $text.rotation, in: -45...45, step: 1)
                    .tint(.accentColor)
            }

            Button(role: .destructive) {
                viewModel.deleteText(text, project: project, context: context)
            } label: {
                Label("text_delete", systemImage: "trash")
                    .frame(maxWidth: .infinity)
            }
            .padding(.top, 2)
        }
    }

    private func weightBinding(_ text: CollageText) -> Binding<TextWeight> {
        Binding(get: { text.weight },
                set: { text.weight = $0; project.touch() })
    }

    private func weightLabel(_ w: TextWeight) -> LocalizedStringKey {
        switch w {
        case .regular: return "weight_regular"
        case .medium:  return "weight_medium"
        case .bold:    return "weight_bold"
        case .heavy:   return "weight_heavy"
        }
    }
}
