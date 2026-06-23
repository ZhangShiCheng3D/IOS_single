//
//  EditorView.swift
//  PixelStudio
//
//  编辑器主界面。自上而下：画布 → 时间轴 → 调色板 → 工具栏。
//  通过 project.modelContext 构造 EditorViewModel，所有编辑都在内存文档中
//  进行并自动持久化。
//

import SwiftUI
import SwiftData

struct EditorView: View {
    @EnvironmentObject private var purchaseManager: PurchaseManager
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let project: PixelProject
    @StateObject private var vm: EditorViewModel

    @State private var showingLayers = false
    @State private var showingExport = false
    @State private var showingRename = false
    @State private var renameText = ""

    init(project: PixelProject) {
        self.project = project
        // SwiftData 取回的模型自带 modelContext；理论上不会为空。
        let context = project.modelContext ?? PreviewData.container.mainContext
        _vm = StateObject(wrappedValue: EditorViewModel(project: project, context: context))
    }

    var body: some View {
        VStack(spacing: 0) {
            canvasArea
            Divider()
            FrameTimelinePanel(vm: vm)
            ColorPalettePanel(vm: vm)
            ToolbarPanel(vm: vm)
        }
        .navigationTitle(project.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
        .sheet(isPresented: $showingLayers) {
            LayerPanel(vm: vm)
        }
        .sheet(isPresented: $showingExport) {
            ExportSheet(vm: vm)
        }
        .sheet(item: $vm.pendingPaywallFeature) { feature in
            PaywallView(highlightedFeature: feature)
        }
        .alert("editor.rename", isPresented: $showingRename) {
            TextField("gallery.name.placeholder", text: $renameText)
            Button("common.cancel", role: .cancel) {}
            Button("common.save") { commitRename() }
        }
        .onAppear { vm.isProUnlocked = purchaseManager.isProUnlocked }
        .onChange(of: purchaseManager.isProUnlocked) { _, newValue in
            vm.isProUnlocked = newValue
        }
        .onDisappear { vm.save() }
    }

    // MARK: - 画布

    private var canvasArea: some View {
        ZStack {
            Color(.systemGroupedBackground)
            PixelCanvasView(vm: vm)
                .padding(12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - 导航栏

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                showingLayers = true
            } label: {
                Image(systemName: "square.stack.3d.up")
            }
            .accessibilityLabel(Text("layer.title"))
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                showingExport = true
            } label: {
                Image(systemName: "square.and.arrow.up")
            }
            .accessibilityLabel(Text("export.title"))
        }
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Button {
                    renameText = project.name
                    showingRename = true
                } label: {
                    Label("editor.rename", systemImage: "pencil")
                }
                Button {
                    vm.clearActiveLayer()
                } label: {
                    Label("layer.clear", systemImage: "xmark.square")
                }
                if !purchaseManager.isProUnlocked {
                    Button {
                        vm.pendingPaywallFeature = .largeCanvas
                    } label: {
                        Label("gallery.pro", systemImage: "crown")
                    }
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .accessibilityLabel(Text("common.more"))
        }
    }

    private func commitRename() {
        let trimmed = renameText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        project.name = trimmed
        project.updatedAt = Date()
        try? modelContext.save()
    }
}

#Preview {
    let container = PreviewData.container
    let project = PreviewData.sampleProject(in: container)
    return NavigationStack {
        EditorView(project: project)
    }
    .modelContainer(container)
    .environmentObject(PurchaseManager())
}
