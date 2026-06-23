//
//  EditorView.swift
//  ShotFrame
//
//  The heart of the app: a live WYSIWYG canvas on top, a tool switcher and the
//  active control panel below. The preview uses the very same `ShotCanvasView`
//  that the exporter renders, so what you see is exactly what you save.
//

import SwiftUI
import SwiftData

/// The editing tools surfaced in the bottom switcher.
enum EditorTool: String, CaseIterable, Identifiable {
    case template, background, frame, adjust, text

    var id: String { rawValue }

    var titleKey: LocalizedStringKey {
        switch self {
        case .template:   return "tool.template"
        case .background: return "tool.background"
        case .frame:      return "tool.frame"
        case .adjust:     return "tool.adjust"
        case .text:       return "tool.text"
        }
    }

    var systemImage: String {
        switch self {
        case .template:   return "square.grid.2x2"
        case .background: return "paintpalette"
        case .frame:      return "iphone"
        case .adjust:     return "slider.horizontal.3"
        case .text:       return "textformat"
        }
    }
}

struct EditorView: View {

    @StateObject private var vm: EditorViewModel
    @EnvironmentObject private var purchases: PurchaseManager
    @Environment(\.dismiss) private var dismiss

    @State private var tool: EditorTool = .template
    @State private var showPaywall = false
    @State private var showExport = false

    init(project: ShotProject, context: ModelContext) {
        _vm = StateObject(wrappedValue: EditorViewModel(project: project, context: context))
    }

    var body: some View {
        VStack(spacing: 0) {
            canvasArea
            Divider()
            toolSwitcher
            panel
                .frame(maxHeight: 280)
        }
        .background(canvasBackdrop.ignoresSafeArea())
        .navigationTitle(vm.project.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showExport = true
                } label: {
                    Label("editor.export", systemImage: "square.and.arrow.up")
                        .font(.body.weight(.semibold))
                }
            }
        }
        .sheet(isPresented: $showPaywall) { PaywallView() }
        .sheet(isPresented: $showExport) {
            ExportView(vm: vm, onNeedsPro: { showExport = false; showPaywall = true })
        }
        .alert(
            "common.error",
            isPresented: Binding(get: { vm.errorMessage != nil }, set: { if !$0 { vm.errorMessage = nil } })
        ) {
            Button("common.ok", role: .cancel) { vm.errorMessage = nil }
        } message: {
            Text(vm.errorMessage ?? "")
        }
    }

    // MARK: - Canvas

    private var canvasArea: some View {
        GeometryReader { geo in
            let inset: CGFloat = 20
            let available = CGSize(width: geo.size.width - inset * 2,
                                   height: geo.size.height - inset * 2)
            let display = displaySize(in: available)

            ZStack {
                ShotCanvasView(
                    image: vm.sourceImage,
                    backgroundImage: vm.backgroundImage,
                    settings: vm.settings,
                    canvasSize: display,
                    showWatermark: !purchases.isPro
                )
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .shadow(color: .black.opacity(0.18), radius: 18, y: 8)
                .overlay {
                    if tool == .text {
                        annotationDragLayer(display: display)
                    }
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    /// Transparent layer that lets the selected annotation be dragged.
    private func annotationDragLayer(display: CGSize) -> some View {
        Color.clear
            .frame(width: display.width, height: display.height)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .local)
                    .onChanged { value in
                        guard vm.selectedAnnotationID != nil else { return }
                        vm.moveSelectedAnnotation(to: CGPoint(
                            x: value.location.x / display.width,
                            y: value.location.y / display.height
                        ))
                    }
                    .onEnded { _ in vm.persist() }
            )
            .overlay(alignment: .topLeading) {
                if let binding = vm.selectedAnnotation {
                    selectionMarker(for: binding.wrappedValue, display: display)
                }
            }
    }

    /// A dashed marker showing which annotation is selected and where.
    private func selectionMarker(for annotation: Annotation, display: CGSize) -> some View {
        RoundedRectangle(cornerRadius: 6, style: .continuous)
            .stroke(Color("AccentColor"), style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
            .frame(width: display.width * 0.42, height: display.height * 0.10)
            .position(x: annotation.position.x * display.width,
                      y: annotation.position.y * display.height)
            .allowsHitTesting(false)
    }

    /// Fit the canvas aspect ratio inside the available area.
    private func displaySize(in bounds: CGSize) -> CGSize {
        let ratio = vm.settings.aspect.ratio ?? (vm.sourceImage?.aspectRatio ?? 1)
        guard bounds.width > 0, bounds.height > 0 else { return CGSize(width: 1, height: 1) }
        if ratio > bounds.width / bounds.height {
            return CGSize(width: bounds.width, height: bounds.width / ratio)
        } else {
            return CGSize(width: bounds.height * ratio, height: bounds.height)
        }
    }

    // MARK: - Tool switcher

    private var toolSwitcher: some View {
        HStack(spacing: 0) {
            ForEach(EditorTool.allCases) { item in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { tool = item }
                    Haptics.selection()
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: item.systemImage)
                            .font(.body)
                        Text(item.titleKey)
                            .font(.caption2)
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(tool == item ? Color("AccentColor") : .secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 10)
        .background(.bar)
    }

    // MARK: - Active panel

    @ViewBuilder
    private var panel: some View {
        ScrollView {
            switch tool {
            case .template:
                TemplatePanel(vm: vm, requestPro: { showPaywall = true })
            case .background:
                BackgroundPanel(vm: vm, requestPro: { showPaywall = true })
            case .frame:
                FramePanel(vm: vm, requestPro: { showPaywall = true })
            case .adjust:
                AdjustPanel(vm: vm)
            case .text:
                TextPanel(vm: vm)
            }
        }
    }

    private var canvasBackdrop: some View {
        LinearGradient(
            colors: [Color(.systemGroupedBackground), Color(.secondarySystemGroupedBackground)],
            startPoint: .top, endPoint: .bottom
        )
    }
}

#Preview {
    NavigationStack {
        EditorView(
            project: ShotProject(name: "Demo", sourceImageData: Data()),
            context: try! ModelContainer(for: ShotProject.self,
                                         configurations: ModelConfiguration(isStoredInMemoryOnly: true)).mainContext
        )
    }
    .environmentObject(PurchaseManager())
}
