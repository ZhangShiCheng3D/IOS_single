//
//  LayerPanel.swift
//  PixelStudio
//
//  图层面板：显示/隐藏、选择、不透明度、上下移动、重命名、清空、删除、新增。
//  以底部弹出 sheet 的形式呈现。
//

import SwiftUI

struct LayerPanel: View {
    @ObservedObject var vm: EditorViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var renameIndex: Int?
    @State private var renameText = ""

    var body: some View {
        NavigationStack {
            List {
                Section {
                    // 顶层在列表上方：逆序展示，符合「上层在上」的直觉。
                    ForEach(layerIndicesTopFirst, id: \.self) { index in
                        layerRow(index)
                    }
                } footer: {
                    if !vm.isProUnlocked {
                        Text(String(format: NSLocalizedString("layer.freeLimit", comment: ""), FreeLimits.maxLayers))
                    }
                }
            }
            .navigationTitle("layer.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("common.done") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        vm.addLayer()
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel(Text("layer.add"))
                }
            }
            .alert("layer.rename", isPresented: Binding(
                get: { renameIndex != nil },
                set: { if !$0 { renameIndex = nil } })) {
                TextField("layer.name.placeholder", text: $renameText)
                Button("common.cancel", role: .cancel) { renameIndex = nil }
                Button("common.save") {
                    if let i = renameIndex { vm.renameLayer(renameText, at: i) }
                    renameIndex = nil
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var layerIndicesTopFirst: [Int] {
        Array((0..<vm.layerCount).reversed())
    }

    private func layerRow(_ index: Int) -> some View {
        let layer = vm.currentFrame.layers[index]
        let isActive = index == vm.currentLayerIndex
        return VStack(spacing: 8) {
            HStack(spacing: 12) {
                Button {
                    vm.toggleLayerVisibility(at: index)
                } label: {
                    Image(systemName: layer.isVisible ? "eye" : "eye.slash")
                        .foregroundStyle(layer.isVisible ? Color.accentColor : Color.secondary)
                }
                .buttonStyle(.plain)

                LayerThumbnail(layer: layer, width: vm.width, height: vm.height)
                    .frame(width: 40, height: 40)

                VStack(alignment: .leading, spacing: 2) {
                    Text(layer.name)
                        .font(.subheadline.weight(isActive ? .semibold : .regular))
                    Text("\(Int(layer.opacity * 100))%")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Menu {
                    Button { startRename(index) } label: {
                        Label("layer.rename", systemImage: "pencil")
                    }
                    Button { vm.moveLayer(from: index, to: min(index + 1, vm.layerCount - 1)) } label: {
                        Label("layer.moveUp", systemImage: "arrow.up")
                    }
                    Button { vm.moveLayer(from: index, to: max(index - 1, 0)) } label: {
                        Label("layer.moveDown", systemImage: "arrow.down")
                    }
                    Button { vm.clearActiveLayer() } label: {
                        Label("layer.clear", systemImage: "xmark.square")
                    }
                    if vm.layerCount > 1 {
                        Button(role: .destructive) {
                            vm.deleteLayer(at: index)
                        } label: {
                            Label("common.delete", systemImage: "trash")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(.secondary)
                }
            }

            if isActive {
                HStack(spacing: 8) {
                    Image(systemName: "circle.lefthalf.filled").font(.caption).foregroundStyle(.secondary)
                    Slider(value: Binding(
                        get: { layer.opacity },
                        set: { vm.setLayerOpacity($0, at: index) }
                    ), in: 0...1)
                }
            }
        }
        .padding(.vertical, 4)
        .listRowBackground(isActive ? Color.accentColor.opacity(0.08) : Color(.systemBackground))
        .contentShape(Rectangle())
        .onTapGesture { vm.currentLayerIndex = index }
    }

    private func startRename(_ index: Int) {
        renameIndex = index
        renameText = vm.currentFrame.layers[index].name
    }
}

/// 单个图层缩略图。
private struct LayerThumbnail: View {
    let layer: WorkingLayer
    let width: Int
    let height: Int

    var body: some View {
        ZStack {
            CheckerboardBackground(cell: 5)
            if let cg = PixelRenderer.image(from: layer.buffer) {
                Image(decorative: cg, scale: 1, orientation: .up)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Color(.separator), lineWidth: 0.5))
    }
}

#Preview {
    let container = PreviewData.container
    let project = PreviewData.sampleProject(in: container)
    return LayerPanel(vm: EditorViewModel(project: project, context: container.mainContext))
}
