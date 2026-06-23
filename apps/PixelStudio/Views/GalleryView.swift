//
//  GalleryView.swift
//  PixelStudio
//
//  作品库首页：网格展示所有像素画，支持新建、打开、重命名、删除。
//

import SwiftUI
import SwiftData

struct GalleryView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var purchaseManager: PurchaseManager
    @Query(sort: \PixelProject.updatedAt, order: .reverse) private var projects: [PixelProject]

    @State private var showingNewProject = false
    @State private var showingPaywall = false
    @State private var showingSettings = false
    @State private var openedProject: PixelProject?
    @State private var renameTarget: PixelProject?
    @State private var renameText = ""
    @State private var deleteTarget: PixelProject?

    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 16)]

    var body: some View {
        NavigationStack {
            Group {
                if projects.isEmpty {
                    emptyState
                } else {
                    grid
                }
            }
            .navigationTitle("gallery.title")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { showingSettings = true } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel(Text("settings.title"))
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if !purchaseManager.isProUnlocked {
                        Button { showingPaywall = true } label: {
                            Label("gallery.pro", systemImage: "crown.fill")
                                .font(.subheadline.weight(.semibold))
                        }
                        .tint(.orange)
                    }
                }
                ToolbarItem(placement: .bottomBar) {
                    Button { showingNewProject = true } label: {
                        Label("gallery.new", systemImage: "plus.circle.fill")
                            .font(.headline)
                    }
                }
            }
            .sheet(isPresented: $showingNewProject) {
                NewProjectSheet { name, size in
                    createProject(name: name, size: size)
                }
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .navigationDestination(item: $openedProject) { project in
                EditorView(project: project)
            }
            .alert("gallery.rename", isPresented: Binding(
                get: { renameTarget != nil },
                set: { if !$0 { renameTarget = nil } })) {
                TextField("gallery.name.placeholder", text: $renameText)
                Button("common.cancel", role: .cancel) { renameTarget = nil }
                Button("common.save") { commitRename() }
            }
            .confirmationDialog(
                Text("gallery.delete.confirm \(deleteTarget?.name ?? "")"),
                isPresented: Binding(
                    get: { deleteTarget != nil },
                    set: { if !$0 { deleteTarget = nil } }),
                titleVisibility: .visible) {
                Button("common.delete", role: .destructive) {
                    if let target = deleteTarget { delete(target) }
                    deleteTarget = nil
                }
                Button("common.cancel", role: .cancel) { deleteTarget = nil }
            } message: {
                Text("gallery.delete.message")
            }
        }
    }

    // MARK: - 子视图

    private var grid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(projects) { project in
                    Button {
                        openedProject = project
                    } label: {
                        ProjectCard(project: project)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button {
                            renameTarget = project
                            renameText = project.name
                        } label: {
                            Label("gallery.rename", systemImage: "pencil")
                        }
                        Button {
                            duplicate(project)
                        } label: {
                            Label("gallery.duplicate", systemImage: "doc.on.doc")
                        }
                        Button(role: .destructive) {
                            deleteTarget = project
                        } label: {
                            Label("common.delete", systemImage: "trash")
                        }
                    }
                }
            }
            .padding(16)
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("gallery.empty.title", systemImage: "paintpalette")
        } description: {
            Text("gallery.empty.detail")
        } actions: {
            Button {
                showingNewProject = true
            } label: {
                Text("gallery.new")
                    .font(.headline)
                    .padding(.horizontal, 8)
            }
            .buttonStyle(.borderedProminent)
        }
    }

    // MARK: - 操作

    private func createProject(name: String, size: Int) {
        let project = PixelProject.makeBlank(name: name, size: size, context: modelContext)
        try? modelContext.save()
        openedProject = project
    }

    private func duplicate(_ project: PixelProject) {
        let copy = PixelProject(name: project.name + " 2",
                                width: project.width,
                                height: project.height,
                                paletteHex: project.paletteHex)
        modelContext.insert(copy)
        var newFrames: [PixelFrame] = []
        for f in project.sortedFrames {
            let nf = PixelFrame(order: f.order, duration: f.duration)
            nf.project = copy
            nf.layers = f.sortedLayers.map { l in
                let nl = PixelLayer(order: l.order, name: l.name,
                                    isVisible: l.isVisible, opacity: l.opacity,
                                    pixelData: l.pixelData)
                nl.frame = nf
                return nl
            }
            newFrames.append(nf)
        }
        copy.frames = newFrames
        try? modelContext.save()
        AppHaptics.impact(.light)
    }

    private func delete(_ project: PixelProject) {
        AppHaptics.impact(.medium)
        withAnimation(.snappy) {
            modelContext.delete(project)
        }
        try? modelContext.save()
    }

    private func commitRename() {
        guard let target = renameTarget else { return }
        let trimmed = renameText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            target.name = trimmed
            target.updatedAt = Date()
            try? modelContext.save()
        }
        renameTarget = nil
    }
}

/// 单张作品卡片。
private struct ProjectCard: View {
    let project: PixelProject

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ThumbnailView(project: project)
                .aspectRatio(1, contentMode: .fit)
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(Color(.separator), lineWidth: 0.5)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(project.name)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                HStack(spacing: 4) {
                    Text("\(project.width)×\(project.height)")
                    if project.frames.count > 1 {
                        Image(systemName: "film").imageScale(.small)
                        Text("\(project.frames.count)")
                    }
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    GalleryView()
        .modelContainer(PreviewData.container)
        .environmentObject(PurchaseManager())
}
