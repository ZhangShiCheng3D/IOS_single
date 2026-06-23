//
//  SlotAdjustPanel.swift
//  CollageKit
//
//  选中已填充插槽时的快捷调整：缩放、复位、替换、删除照片。
//

import SwiftUI
import PhotosUI
import SwiftData

struct SlotAdjustPanel: View {
    @Bindable var project: CollageProject
    @ObservedObject var viewModel: EditorViewModel
    let slotIndex: Int
    @Environment(\.modelContext) private var context

    @State private var pickerItem: PhotosPickerItem?

    private var photo: CollagePhoto? { project.photo(forSlot: slotIndex) }

    var body: some View {
        VStack(spacing: 12) {
            if let photo {
                @Bindable var photo = photo
                HStack {
                    Image(systemName: "magnifyingglass")
                    Slider(value: $photo.scale, in: 1...3, step: 0.01) { editing in
                        if !editing { project.touch() }
                    }
                    .tint(.accentColor)
                }

                HStack(spacing: 12) {
                    PhotosPicker(selection: $pickerItem, matching: .images) {
                        actionLabel("slot_replace", systemImage: "photo.on.rectangle")
                    }
                    Button {
                        photo.scale = 1; photo.offsetX = 0; photo.offsetY = 0
                        project.touch()
                    } label: {
                        actionLabel("slot_reset", systemImage: "arrow.counterclockwise")
                    }
                    Button(role: .destructive) {
                        viewModel.clearSlot(slotIndex, project: project, context: context)
                        viewModel.selectedSlotIndex = nil
                    } label: {
                        actionLabel("slot_remove", systemImage: "trash")
                    }
                }
            }
        }
        .onChange(of: pickerItem) { _, item in
            guard let item else { return }
            Task {
                await viewModel.setPhoto(item, slotIndex: slotIndex,
                                         project: project, context: context)
                pickerItem = nil
            }
        }
    }

    private func actionLabel(_ title: LocalizedStringKey, systemImage: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: systemImage).font(.system(size: 18))
            Text(title).font(.caption2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}
