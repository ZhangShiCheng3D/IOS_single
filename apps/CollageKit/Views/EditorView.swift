//
//  EditorView.swift
//  CollageKit
//
//  拼图编辑器主界面：顶部操作栏、实时画布、上下文调整条、底部工具面板。
//

import SwiftUI
import SwiftData
import PhotosUI

struct EditorView: View {
    @Bindable var project: CollageProject

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: PurchaseManager
    @Query(sort: \UserPreset.createdAt, order: .reverse) private var presets: [UserPreset]

    @StateObject private var viewModel = EditorViewModel()

    @State private var activeTool: Tool = .templates
    @State private var showExport = false
    @State private var showPaywall = false
    @State private var showTemplatePicker = false

    // 空插槽选图
    @State private var pickerPresented = false
    @State private var pickerSlot: Int?
    @State private var pickerItem: PhotosPickerItem?

    // 保存预设
    @State private var showSavePreset = false
    @State private var presetName = ""

    enum Tool: String, CaseIterable, Identifiable {
        case templates, ratio, layout, background, text, presets
        var id: String { rawValue }
        var title: LocalizedStringKey {
            switch self {
            case .templates:  return "tool_templates"
            case .ratio:      return "tool_ratio"
            case .layout:     return "tool_layout"
            case .background: return "tool_background"
            case .text:       return "tool_text"
            case .presets:    return "tool_presets"
            }
        }
        var icon: String {
            switch self {
            case .templates:  return "square.grid.2x2"
            case .ratio:      return "aspectratio"
            case .layout:     return "slider.horizontal.3"
            case .background: return "paintpalette"
            case .text:       return "textformat"
            case .presets:    return "bookmark"
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            canvasArea
            Divider()
            contextBar
            toolPanel
            toolBar
        }
        .navigationTitle(project.title.isEmpty ? String(localized: "untitled_project") : project.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
        .background(Color(.systemGroupedBackground))
        .onAppear { viewModel.prepare(project: project) }
        .photosPicker(isPresented: $pickerPresented, selection: $pickerItem, matching: .images)
        .onChange(of: pickerItem) { _, item in handlePickedPhoto(item) }
        .sheet(isPresented: $showExport) {
            ExportPreviewView(project: project, viewModel: viewModel)
                .environmentObject(store)
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView().environmentObject(store)
        }
        .sheet(isPresented: $showTemplatePicker) {
            TemplatePickerView(isPro: store.isPro,
                               onSelect: applyTemplate,
                               onNeedPro: { showTemplatePicker = false; showPaywall = true })
        }
        .alert("preset_save_title", isPresented: $showSavePreset) {
            TextField("preset_name_placeholder", text: $presetName)
            Button("save") { saveCurrentPreset() }
            Button("cancel", role: .cancel) {}
        }
        .alert("alert_title", isPresented: Binding(
            get: { viewModel.statusMessage != nil },
            set: { if !$0 { viewModel.statusMessage = nil } }
        )) {
            Button("ok", role: .cancel) { viewModel.statusMessage = nil }
        } message: {
            Text(viewModel.statusMessage ?? "")
        }
    }

    // MARK: - 顶部栏

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                showExport = true
            } label: {
                Label("export", systemImage: "square.and.arrow.up")
                    .fontWeight(.semibold)
            }
        }
    }

    // MARK: - 画布

    private var canvasArea: some View {
        CollageCanvasView(project: project, viewModel: viewModel) { slot in
            pickerSlot = slot
            pickerPresented = true
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }

    // MARK: - 上下文调整条

    @ViewBuilder
    private var contextBar: some View {
        if let slot = viewModel.selectedSlotIndex,
           project.photo(forSlot: slot) != nil {
            SlotAdjustPanel(project: project, viewModel: viewModel, slotIndex: slot)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(.systemBackground))
                .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    // MARK: - 工具面板

    private var toolPanel: some View {
        ScrollView {
            Group {
                switch activeTool {
                case .templates:  templateStrip
                case .ratio:      ratioPanel
                case .layout:     LayoutPanel(project: project)
                case .background: BackgroundPanel(project: project)
                case .text:       TextPanel(project: project, viewModel: viewModel)
                case .presets:    presetPanel
                }
            }
            .padding(16)
        }
        .frame(height: 220)
        .background(Color(.systemBackground))
    }

    private var templateStrip: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("tool_templates").font(.subheadline.weight(.semibold))
                Spacer()
                Button("templates_browse_all") { showTemplatePicker = true }
                    .font(.caption.weight(.medium))
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(TemplateLibrary.all) { tpl in
                        let locked = tpl.isPremium && !store.isPro
                        Button {
                            if locked { showPaywall = true } else { applyTemplate(tpl) }
                        } label: {
                            ZStack(alignment: .topTrailing) {
                                TemplateThumbnailView(template: tpl)
                                    .padding(8)
                                    .frame(width: 84, height: 100)
                                    .background(Color(.secondarySystemBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.accentColor,
                                                    lineWidth: project.templateID == tpl.id ? 2.5 : 0)
                                    )
                                if locked {
                                    Image(systemName: "lock.fill")
                                        .font(.caption2.weight(.bold))
                                        .padding(5)
                                        .background(.ultraThinMaterial, in: Circle())
                                        .padding(4)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(Text(tpl.name))
                        .accessibilityAddTraits(locked ? [] : (project.templateID == tpl.id ? .isSelected : []))
                    }
                }
            }
        }
    }

    private var ratioPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("tool_ratio").font(.subheadline.weight(.semibold))
            HStack(spacing: 12) {
                ForEach(AspectRatio.allCases) { ratio in
                    let locked = ratio == .story && !store.isPro
                    Button {
                        if locked { showPaywall = true }
                        else { project.aspectRatio = ratio; project.touch() }
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: ratio.systemImage).font(.title3)
                            Text(ratio.displayName).font(.caption)
                            if locked {
                                Image(systemName: "lock.fill").font(.caption2)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(project.aspectRatio == ratio
                                    ? Color.accentColor.opacity(0.15)
                                    : Color(.secondarySystemBackground))
                        .foregroundStyle(project.aspectRatio == ratio ? Color.accentColor : .primary)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var presetPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                presetName = ""
                showSavePreset = true
            } label: {
                Label("preset_save_current", systemImage: "bookmark.fill")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color.accentColor.opacity(0.12))
                    .foregroundStyle(Color.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            if presets.isEmpty {
                Text("preset_empty")
                    .font(.footnote).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 6)
            } else {
                ForEach(presets) { preset in
                    HStack {
                        Image(systemName: "bookmark")
                        Text(preset.name).font(.subheadline)
                        Spacer()
                        Button("preset_apply") { preset.apply(to: project) }
                            .font(.caption.weight(.medium))
                        Button(role: .destructive) {
                            context.delete(preset)
                        } label: {
                            Image(systemName: "trash").font(.caption)
                        }
                    }
                    .padding(.vertical, 6)
                }
            }
        }
    }

    // MARK: - 底部工具栏

    private var toolBar: some View {
        HStack {
            ForEach(Tool.allCases) { tool in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { activeTool = tool }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tool.icon).font(.system(size: 18))
                        Text(tool.title).font(.caption2)
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(activeTool == tool ? Color.accentColor : .secondary)
                }
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 8)
        .background(.bar)
    }

    // MARK: - 行为

    private func applyTemplate(_ tpl: CollageTemplate) {
        // 切换模板后，清理超出新插槽数量的照片（含缓存）。
        DesignSystem.Haptics.selection()
        withAnimation(.easeInOut(duration: 0.2)) {
            viewModel.applyTemplateChange(to: project, template: tpl, context: context)
        }
    }

    private func handlePickedPhoto(_ item: PhotosPickerItem?) {
        guard let item, let slot = pickerSlot else { return }
        Task {
            await viewModel.setPhoto(item, slotIndex: slot, project: project, context: context)
            pickerItem = nil
            pickerSlot = nil
        }
    }

    private func saveCurrentPreset() {
        let name = presetName.trimmingCharacters(in: .whitespaces)
        let preset = UserPreset(name: name.isEmpty ? String(localized: "preset_default_name") : name,
                                project: project)
        context.insert(preset)
    }
}

#Preview {
    NavigationStack {
        EditorView(project: CollageProject())
            .environmentObject(PurchaseManager())
    }
    .modelContainer(for: [CollageProject.self, CollagePhoto.self,
                          CollageText.self, UserPreset.self], inMemory: true)
}
