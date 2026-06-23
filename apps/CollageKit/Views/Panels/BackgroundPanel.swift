//
//  BackgroundPanel.swift
//  CollageKit
//
//  背景面板：纯色 / 渐变切换，预设色板、自定义取色、渐变角度。
//

import SwiftUI

struct BackgroundPanel: View {
    @Bindable var project: CollageProject

    /// 预设纯色色板。
    private let solidSwatches = [
        "#FFFFFF", "#000000", "#F7F4EF", "#FDE4CF", "#C8B6FF",
        "#BDE0FE", "#A0E8AF", "#FFC2D1", "#FFD6A5", "#2B2B2B"
    ]

    /// 预设渐变（起止色）。
    private let gradientSwatches: [(String, String)] = [
        ("#FDE4CF", "#C8B6FF"),
        ("#BDE0FE", "#A0E8AF"),
        ("#FFC2D1", "#FFD6A5"),
        ("#84FAB0", "#8FD3F4"),
        ("#A18CD1", "#FBC2EB"),
        ("#FAD0C4", "#FFD1FF")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Picker("background_kind", selection: kindBinding) {
                ForEach(BackgroundKind.allCases) { kind in
                    Text(kind.displayName).tag(kind)
                }
            }
            .pickerStyle(.segmented)

            if project.backgroundKind == .solid {
                solidSection
            } else {
                gradientSection
            }
        }
        .animation(.easeInOut(duration: 0.2), value: project.backgroundKindRaw)
    }

    private var kindBinding: Binding<BackgroundKind> {
        Binding(get: { project.backgroundKind },
                set: { project.backgroundKind = $0; project.touch() })
    }

    // MARK: - 纯色

    private var solidSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            swatchGrid(solidSwatches) { hex in
                project.backgroundColorHex = hex
                project.touch()
            } isSelected: { $0 == project.backgroundColorHex }

            ColorPicker(selection: Binding(
                get: { Color(hex: project.backgroundColorHex) },
                set: { project.backgroundColorHex = $0.hexString; project.touch() }
            )) {
                Text("background_custom_color").font(.subheadline)
            }
        }
    }

    // MARK: - 渐变

    private var gradientSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 6), spacing: 10) {
                ForEach(gradientSwatches, id: \.0) { pair in
                    let selected = pair.0 == project.gradientStartHex && pair.1 == project.gradientEndHex
                    Circle()
                        .fill(LinearGradient(colors: [Color(hex: pair.0), Color(hex: pair.1)],
                                             startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(height: 40)
                        .overlay(Circle().stroke(Color.accentColor, lineWidth: selected ? 3 : 0))
                        .onTapGesture {
                            project.gradientStartHex = pair.0
                            project.gradientEndHex = pair.1
                            project.touch()
                        }
                }
            }

            HStack(spacing: 16) {
                ColorPicker("", selection: Binding(
                    get: { Color(hex: project.gradientStartHex) },
                    set: { project.gradientStartHex = $0.hexString; project.touch() }
                )).labelsHidden()
                ColorPicker("", selection: Binding(
                    get: { Color(hex: project.gradientEndHex) },
                    set: { project.gradientEndHex = $0.hexString; project.touch() }
                )).labelsHidden()
                Spacer()
                Text("background_angle").font(.subheadline).foregroundStyle(.secondary)
            }

            Slider(value: Binding(
                get: { project.gradientAngle },
                set: { project.gradientAngle = $0; project.touch() }
            ), in: 0...360, step: 1)
            .tint(.accentColor)
        }
    }

    // MARK: - 复用

    private func swatchGrid(_ hexes: [String],
                            onSelect: @escaping (String) -> Void,
                            isSelected: @escaping (String) -> Bool) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 5), spacing: 10) {
            ForEach(hexes, id: \.self) { hex in
                Circle()
                    .fill(Color(hex: hex))
                    .frame(height: 40)
                    .overlay(Circle().stroke(Color(.separator), lineWidth: 0.5))
                    .overlay(Circle().stroke(Color.accentColor, lineWidth: isSelected(hex) ? 3 : 0))
                    .onTapGesture { onSelect(hex) }
            }
        }
    }
}

#Preview {
    BackgroundPanel(project: CollageProject())
        .padding()
}
