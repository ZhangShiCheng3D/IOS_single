//
//  PhotoDetailView.swift
//  RetroFilm
//
//  Full-screen photo viewer + re-edit. Lets the user apply a different film
//  stock ("二次滤镜"), fine-tune parameters, export to Photos, share, or delete.
//

import SwiftUI
import SwiftData

struct PhotoDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: PurchaseManager

    let photo: CapturedPhoto
    @StateObject private var model: PhotoEditViewModel

    @State private var showAdjustments = false
    @State private var showPaywall = false
    @State private var showDeleteConfirm = false
    @State private var shareItem: UIImage?

    init(photo: CapturedPhoto) {
        self.photo = photo
        _model = StateObject(wrappedValue: PhotoEditViewModel(photo: photo))
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                imageArea
                FilmWheelView(
                    selected: $model.stock,
                    isUnlocked: store.isUnlocked,
                    onLockedTapped: { showPaywall = true }
                )
                .padding(.vertical, 8)
            }
        }
        .preferredColorScheme(.dark)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
        .onAppear { model.scheduleRender() }
        .onChange(of: model.stock) { _, _ in model.scheduleRender() }
        .onChange(of: model.settings) { _, _ in model.scheduleRender() }
        .sheet(isPresented: $showAdjustments) {
            AdjustmentPanel(settings: $model.settings)
                .presentationDetents([.height(340)])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showPaywall) { PaywallView().environmentObject(store) }
        .sheet(item: $shareItem) { item in
            ShareSheet(items: [item])
        }
        .confirmationDialog("detail.delete.confirm", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("action.delete", role: .destructive) { deletePhoto() }
        }
        .overlay(alignment: .bottom) { exportToast }
    }

    // MARK: - Image area

    private var imageArea: some View {
        ZStack {
            if let preview = model.preview {
                Image(uiImage: preview)
                    .resizable()
                    .scaledToFit()
            } else {
                ProgressView().tint(.white)
            }
            if model.isRendering {
                ProgressView()
                    .tint(.white)
                    .padding(10)
                    .background(.ultraThinMaterial, in: Circle())
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .padding()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Button { showAdjustments = true } label: {
                    Label("adjust.title", systemImage: "slider.horizontal.3")
                }
                Button { model.exportToPhotos() } label: {
                    Label("detail.export", systemImage: "square.and.arrow.down")
                }
                Button { shareItem = model.preview } label: {
                    Label("detail.share", systemImage: "square.and.arrow.up")
                }
                Button { saveEdits() } label: {
                    Label("detail.save", systemImage: "checkmark.circle")
                }
                Divider()
                Button(role: .destructive) { showDeleteConfirm = true } label: {
                    Label("action.delete", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
    }

    @ViewBuilder
    private var exportToast: some View {
        if let message = model.exportMessage {
            Text(message)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 16).padding(.vertical, 10)
                .background(.ultraThinMaterial, in: Capsule())
                .softShadow(radius: 10, y: 4)
                .padding(.bottom, 100)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .task {
                    try? await Task.sleep(nanoseconds: 1_800_000_000)
                    withAnimation { model.exportMessage = nil }
                }
        }
    }

    // MARK: - Actions

    private func saveEdits() {
        model.saveEdits(to: photo, context: ModelContextBox { try? modelContext.save() })
    }

    private func deletePhoto() {
        PhotoStorage.shared.delete(photo)
        modelContext.delete(photo)
        try? modelContext.save()
        dismiss()
    }
}

/// UIKit share sheet bridge.
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}

/// Allow `UIImage` to drive `.sheet(item:)`.
extension UIImage: @retroactive Identifiable {
    public var id: Int { hashValue }
}

#Preview {
    NavigationStack {
        PhotoDetailView(photo: CapturedPhoto(
            filmStockID: FilmStock.portra400.id,
            settings: .default,
            originalFileName: "x", renderedFileName: "x", thumbnailFileName: "x"))
        .environmentObject(PurchaseManager())
    }
}
