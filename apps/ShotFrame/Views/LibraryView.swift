//
//  LibraryView.swift
//  ShotFrame
//
//  Home screen: a grid of saved projects plus entry points for importing a
//  new screenshot, batch processing, and settings. New screenshots are
//  imported with the system photo picker and open straight into the editor.
//

import SwiftUI
import SwiftData
import PhotosUI

struct LibraryView: View {

    @Environment(\.modelContext) private var context
    @EnvironmentObject private var purchases: PurchaseManager

    /// Saved projects, newest first.
    @Query(sort: \ShotProject.updatedAt, order: .reverse) private var projects: [ShotProject]

    @State private var importItem: PhotosPickerItem?
    @State private var openProject: ShotProject?
    @State private var showBatch = false
    @State private var showSettings = false
    @State private var showPaywall = false
    @State private var importError: String?

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
            .navigationTitle("library.title")
            .toolbar { toolbarContent }
            .navigationDestination(item: $openProject) { project in
                EditorView(project: project, context: context)
            }
            .sheet(isPresented: $showBatch) { BatchView() }
            .sheet(isPresented: $showSettings) { SettingsView() }
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .onChange(of: importItem) { _, item in
                guard let item else { return }
                Task { await importScreenshot(item) }
            }
            .alert(
                "common.error",
                isPresented: Binding(get: { importError != nil }, set: { if !$0 { importError = nil } })
            ) {
                Button("common.ok", role: .cancel) { importError = nil }
            } message: {
                Text(importError ?? "")
            }
        }
    }

    // MARK: - Grid

    private var grid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(projects) { project in
                    Button {
                        openProject = project
                    } label: {
                        ProjectCell(project: project)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button(role: .destructive) {
                            delete(project)
                        } label: {
                            Label("common.delete", systemImage: "trash")
                        }
                    }
                }
            }
            .padding(16)
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 64))
                .foregroundStyle(Color("AccentColor").gradient)
            Text("library.empty.title")
                .font(.title2.bold())
            Text("library.empty.subtitle")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            PhotosPicker(selection: $importItem, matching: .images) {
                Label("library.import", systemImage: "plus")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .foregroundStyle(.white)
                    .background(Color("AccentColor").gradient, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .padding(.horizontal, 40)
            .padding(.top, 8)
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape")
            }
            .accessibilityLabel(Text("settings.title"))
        }

        ToolbarItemGroup(placement: .topBarTrailing) {
            if !purchases.isPro {
                Button {
                    showPaywall = true
                } label: {
                    Label("library.pro", systemImage: "crown.fill")
                        .labelStyle(.titleAndIcon)
                        .font(.subheadline.weight(.semibold))
                }
                .tint(.orange)
            }

            Button {
                showBatch = true
            } label: {
                Image(systemName: "square.stack.3d.up")
            }
            .accessibilityLabel(Text("batch.title"))

            PhotosPicker(selection: $importItem, matching: .images) {
                Image(systemName: "plus")
            }
            .accessibilityLabel(Text("library.import"))
        }
    }

    // MARK: - Actions

    @MainActor
    private func importScreenshot(_ item: PhotosPickerItem) async {
        defer { importItem = nil }
        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else {
                importError = NSLocalizedString("error.import", comment: "")
                return
            }
            // Cap very large screenshots to keep memory and store size sane.
            let capped = image.downscaled(maxDimension: 3000)
            let storedData = capped.jpegData(compressionQuality: 0.95) ?? data

            let project = ShotProject(
                name: defaultName(),
                sourceImageData: storedData,
                settings: TemplateLibrary.free.first?.settings ?? .default
            )
            context.insert(project)
            try? context.save()
            openProject = project
        } catch {
            importError = error.localizedDescription
        }
    }

    private func delete(_ project: ShotProject) {
        context.delete(project)
        try? context.save()
        Haptics.tap()
    }

    private func defaultName() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, HH:mm"
        return formatter.string(from: Date())
    }
}

// MARK: - Project cell

/// A single thumbnail in the library grid. Renders a small, cached preview
/// using the same canvas pipeline as the editor.
private struct ProjectCell: View {
    let project: ShotProject
    @State private var thumbnail: UIImage?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.quaternary)
                if let thumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                } else {
                    ProgressView()
                }
            }
            .frame(height: 160)

            Text(project.name)
                .font(.subheadline.weight(.medium))
                .lineLimit(1)
                .foregroundStyle(.primary)
        }
        .task(id: project.updatedAt) {
            thumbnail = CanvasRenderer.render(
                image: project.sourceImage,
                backgroundImage: project.backgroundImage,
                settings: project.settings,
                longEdge: 420,
                watermark: false
            )
        }
    }
}

#Preview {
    LibraryView()
        .environmentObject(PurchaseManager())
        .modelContainer(for: ShotProject.self, inMemory: true)
}
