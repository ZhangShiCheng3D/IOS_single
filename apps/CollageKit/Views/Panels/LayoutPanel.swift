//
//  LayoutPanel.swift
//  CollageKit
//
//  布局面板：调整外边框、插槽间距、圆角。
//

import SwiftUI

struct LayoutPanel: View {
    @Bindable var project: CollageProject

    var body: some View {
        VStack(spacing: 18) {
            sliderRow(title: "layout_border",
                      systemImage: "square.dashed",
                      value: $project.borderWidth,
                      range: 0...40)
            sliderRow(title: "layout_spacing",
                      systemImage: "rectangle.split.2x1",
                      value: $project.spacing,
                      range: 0...40)
            sliderRow(title: "layout_corner",
                      systemImage: "rotate.left",
                      value: $project.cornerRadius,
                      range: 0...40)
        }
        .padding(.vertical, 4)
    }

    private func sliderRow(title: LocalizedStringKey,
                           systemImage: String,
                           value: Binding<Double>,
                           range: ClosedRange<Double>) -> some View {
        VStack(spacing: 6) {
            HStack {
                Label(title, systemImage: systemImage)
                    .font(.subheadline.weight(.medium))
                Spacer()
                Text("\(Int(value.wrappedValue))")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Slider(value: value, in: range, step: 1) { editing in
                if !editing { project.touch() }
            }
            .tint(.accentColor)
        }
    }
}

#Preview {
    LayoutPanel(project: CollageProject())
        .padding()
}
