//
//  BatchView.swift
//  ShotFrame
//
//  Batch mode: pick many screenshots at once, apply one template to all, and
//  save the finished images to Photos in a single pass. Batch is a Pro feature.
//

import SwiftUI
import PhotosUI

struct BatchView: View {

    @EnvironmentObject private var purchases: PurchaseManager
    @Environment(\.dismiss) private var dismiss

    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var images: [UIImage] = []
    @State private var template: ShotTemplate = TemplateLibrary.free.first ?? TemplateLibrary.all[0]
    @State private var isProcessing = false
    @State private var progress: Double = 0
    @State private var resultMessage: String?
    @State private var errorMessage: String?
    @State private var showPaywall = false

    private let columns = [GridItem(.adaptive(minimum: 80), spacing: 10)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    picker
                    if !images.isEmpty {
                        thumbnails
                        templateChooser
                        processButton
                    } else {
                        hint
                    }
                }
                .padding(20)
            }
            .navigationTitle("batch.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("common.done") { dismiss() }
                }
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .onChange(of: pickerItems) { _, items in
                Task { await load(items) }
            }
            .alert(
                "common.error",
                isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })
            ) {
                Button("common.ok", role: .cancel) { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
            .overlay(alignment: .bottom) {
                if let resultMessage {
                    Label(resultMessage, systemImage: "checkmark.circle.fill")
                        .font(.subheadline.weight(.medium))
                        .padding(.horizontal, 18).padding(.vertical, 12)
                        .background(.regularMaterial, in: Capsule())
                        .padding(.bottom, 24)
                        .task {
                            try? await Task.sleep(for: .seconds(1.8))
                            self.resultMessage = nil
                        }
                }
            }
        }
    }

    // MARK: - Sections

    private var picker: some View {
        PhotosPicker(selection: $pickerItems, maxSelectionCount: 30, matching: .images) {
            Label("batch.select", systemImage: "photo.stack")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .foregroundStyle(.white)
                .background(Color("AccentColor").gradient, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    private var hint: some View {
        VStack(spacing: 10) {
            Image(systemName: "square.stack.3d.up")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("batch.hint")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
    }

    private var thumbnails: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("batch.count \(images.count)")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(Array(images.enumerated()), id: \.offset) { _, image in
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            }
        }
    }

    private var templateChooser: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("batch.template")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(TemplateLibrary.all) { tpl in
                        Button {
                            if tpl.isPro && !purchases.isPro {
                                showPaywall = true
                            } else {
                                template = tpl
                                Haptics.selection()
                            }
                        } label: {
                            VStack(spacing: 4) {
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(LinearGradient(colors: tpl.swatch.map(\.color),
                                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(width: 64, height: 64)
                                    .overlay(alignment: .topTrailing) {
                                        if tpl.isPro && !purchases.isPro { ProLockBadge().padding(4) }
                                    }
                                    .overlay {
                                        if template.id == tpl.id {
                                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                .strokeBorder(Color("AccentColor"), lineWidth: 3)
                                        }
                                    }
                                Text(tpl.name).font(.caption2).lineLimit(1)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var processButton: some View {
        VStack(spacing: 10) {
            Button {
                if purchases.isPro {
                    Task { await process() }
                } else {
                    showPaywall = true
                }
            } label: {
                HStack {
                    if isProcessing {
                        ProgressView(value: progress).tint(.white).frame(width: 120)
                    } else if purchases.isPro {
                        Label("batch.process \(images.count)", systemImage: "wand.and.sparkles")
                    } else {
                        Label("batch.unlock", systemImage: "crown.fill")
                    }
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .foregroundStyle(.white)
                .background((purchases.isPro ? AnyShapeStyle(Color("AccentColor").gradient) : AnyShapeStyle(Color.orange.gradient)),
                            in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .disabled(isProcessing)
        }
    }

    // MARK: - Actions

    @MainActor
    private func load(_ items: [PhotosPickerItem]) async {
        var loaded: [UIImage] = []
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                loaded.append(image.downscaled(maxDimension: 2400))
            }
        }
        images = loaded
    }

    @MainActor
    private func process() async {
        guard !images.isEmpty else { return }
        isProcessing = true
        progress = 0
        defer { isProcessing = false }

        var outputs: [UIImage] = []
        for (index, image) in images.enumerated() {
            if let out = CanvasRenderer.render(
                image: image,
                backgroundImage: nil,
                settings: template.settings,
                resolution: .standard,
                watermark: false // Pro-gated, so never watermarked
            ) {
                outputs.append(out)
            }
            progress = Double(index + 1) / Double(images.count)
        }

        do {
            try await PhotoLibrary.save(outputs)
            resultMessage = String(format: NSLocalizedString("batch.done", comment: ""), outputs.count)
            Haptics.success()
        } catch {
            errorMessage = error.localizedDescription
            Haptics.warning()
        }
    }
}

#Preview {
    BatchView()
        .environmentObject(PurchaseManager())
}
