//
//  MoodPicker.swift
//  OneWord
//
//  Horizontal palette of mood emojis with a selection highlight.
//

import SwiftUI

struct MoodPicker: View {
    @Binding var selection: String
    var onChange: (() -> Void)?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.sm) {
                ForEach(MoodEmoji.palette) { mood in
                    let isSelected = selection == mood.emoji
                    Button {
                        Haptics.selection()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            selection = mood.emoji
                        }
                        onChange?()
                    } label: {
                        Text(mood.emoji)
                            .font(.system(size: 32))
                            .frame(width: 52, height: 52)
                            .background(
                                Circle()
                                    .fill(isSelected ? Theme.accent.opacity(0.18) : Color.clear)
                            )
                            .overlay(
                                Circle()
                                    .strokeBorder(
                                        isSelected ? Theme.accent : .clear,
                                        lineWidth: 2
                                    )
                            )
                            .scaleEffect(isSelected ? 1.08 : 1)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text(LocalizedStringKey(mood.nameKey)))
                    .accessibilityAddTraits(selection == mood.emoji ? [.isSelected] : [])
                }
            }
            .padding(.horizontal, 2)
            .padding(.vertical, 4)
        }
    }
}

#Preview {
    StatefulPreviewWrapper("🙂") { binding in
        MoodPicker(selection: binding)
            .padding()
    }
}

/// Small helper so `@Binding`-based components can be previewed.
struct StatefulPreviewWrapper<Value, Content: View>: View {
    @State private var value: Value
    private let content: (Binding<Value>) -> Content

    init(_ initial: Value, @ViewBuilder content: @escaping (Binding<Value>) -> Content) {
        _value = State(initialValue: initial)
        self.content = content
    }

    var body: some View { content($value) }
}
