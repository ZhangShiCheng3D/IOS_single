//
//  ColorPalettePanel.swift
//  PixelStudio
//
//  调色板：当前色 + 取色器、横向色块选择、长按编辑/删除、添加颜色。
//

import SwiftUI

struct ColorPalettePanel: View {
    @ObservedObject var vm: EditorViewModel

    @State private var editingColor: Color = .black
    @State private var showingPicker = false
    @State private var editTargetIndex: Int?

    var body: some View {
        HStack(spacing: 12) {
            currentColorWell

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(vm.palette.enumerated()), id: \.offset) { index, color in
                        swatch(color, index: index)
                    }
                    addButton
                }
                .padding(.vertical, 4)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.bar)
        .sheet(isPresented: $showingPicker) {
            colorEditorSheet
        }
    }

    // MARK: - 当前色

    private var currentColorWell: some View {
        VStack(spacing: 4) {
            ZStack {
                CheckerboardBackground(cell: 6)
                    .frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(vm.currentColor.color)
                    .frame(width: 44, height: 44)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(Color(.separator), lineWidth: 1)
                    )
            }
            .onTapGesture {
                editTargetIndex = nil
                editingColor = vm.currentColor.color
                showingPicker = true
            }
            .accessibilityElement()
            .accessibilityLabel(Text("palette.current"))
            .accessibilityValue(Text(vm.currentColor.hexString))
            .accessibilityAddTraits(.isButton)
        }
    }

    // MARK: - 色块

    private func swatch(_ color: PixelColor, index: Int) -> some View {
        let isSelected = color == vm.currentColor
        return RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(color.color)
            .frame(width: 36, height: 36)
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(isSelected ? Color.accentColor : Color(.separator),
                                  lineWidth: isSelected ? 3 : 1)
            )
            .animation(.snappy(duration: 0.15), value: isSelected)
            .accessibilityElement()
            .accessibilityLabel(Text("palette.colorTitle"))
            .accessibilityValue(Text(color.hexString))
            .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
            .onTapGesture {
                guard color != vm.currentColor else { return }
                AppHaptics.selection()
                vm.selectColor(color)
            }
            .contextMenu {
                Button {
                    editTargetIndex = index
                    editingColor = color.color
                    showingPicker = true
                } label: {
                    Label("palette.edit", systemImage: "pencil")
                }
                Button(role: .destructive) {
                    vm.removePaletteColor(at: index)
                } label: {
                    Label("common.delete", systemImage: "trash")
                }
            }
    }

    private var addButton: some View {
        Button {
            AppHaptics.impact(.light)
            vm.addCurrentColorToPalette()
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 16, weight: .semibold))
                .frame(width: 36, height: 36)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .foregroundStyle(.secondary)
        }
        .accessibilityLabel(Text("palette.add"))
    }

    // MARK: - 颜色编辑

    private var colorEditorSheet: some View {
        NavigationStack {
            VStack(spacing: 20) {
                ColorPicker("palette.pick", selection: $editingColor, supportsOpacity: false)
                    .padding()
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))

                RoundedRectangle(cornerRadius: 12)
                    .fill(editingColor)
                    .frame(height: 80)
                    .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color(.separator)))

                Spacer()
            }
            .padding()
            .navigationTitle("palette.colorTitle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel") { showingPicker = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.done") { applyColorEdit() }.bold()
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func applyColorEdit() {
        let pixel = PixelColor(editingColor)
        if let index = editTargetIndex {
            vm.updatePaletteColor(pixel, at: index)
        } else {
            vm.selectColor(pixel)
        }
        showingPicker = false
    }
}

#Preview {
    let container = PreviewData.container
    let project = PreviewData.sampleProject(in: container)
    return ColorPalettePanel(vm: EditorViewModel(project: project, context: container.mainContext))
}
