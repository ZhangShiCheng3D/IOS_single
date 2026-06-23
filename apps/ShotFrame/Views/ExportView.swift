//
//  ExportView.swift
//  ShotFrame
//
//  Export sheet: pick a resolution, preview the result, then save to Photos or
//  share. Free exports carry a small watermark; unlocking Pro removes it.
//

import SwiftUI

struct ExportView: View {
    @ObservedObject var vm: EditorViewModel
    let onNeedsPro: () -> Void

    @EnvironmentObject private var purchases: PurchaseManager
    @Environment(\.dismiss) private var dismiss

    @State private var resolution: ExportResolution = .standard
    @State private var rendered: UIImage?

    /// Free users get a watermark on the exported file.
    private var watermark: Bool { !purchases.isPro }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    preview
                    resolutionPicker
                    if !purchases.isPro { watermarkBanner }
                    actions
                }
                .padding(20)
            }
            .navigationTitle("export.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("common.done") { dismiss() }
                }
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .task(id: ExportKey(resolution: resolution, isPro: purchases.isPro)) {
                rendered = vm.renderImage(resolution: resolution, watermark: watermark)
            }
            .alert(
                "common.error",
                isPresented: Binding(get: { vm.errorMessage != nil }, set: { if !$0 { vm.errorMessage = nil } })
            ) {
                Button("common.ok", role: .cancel) { vm.errorMessage = nil }
            } message: {
                Text(vm.errorMessage ?? "")
            }
            .overlay(alignment: .bottom) {
                if let message = vm.statusMessage {
                    toast(message)
                        .task {
                            try? await Task.sleep(for: .seconds(1.6))
                            vm.statusMessage = nil
                        }
                }
            }
        }
    }

    // MARK: - Sections

    private var preview: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.quaternary)
            if let rendered {
                Image(uiImage: rendered)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            } else {
                ProgressView()
            }
        }
        .frame(height: 300)
    }

    private var resolutionPicker: some View {
        Picker("export.resolution", selection: $resolution) {
            ForEach(ExportResolution.allCases) { res in
                Text(res.titleKey).tag(res)
            }
        }
        .pickerStyle(.segmented)
    }

    private var watermarkBanner: some View {
        Button(action: onNeedsPro) {
            HStack(spacing: 12) {
                Image(systemName: "crown.fill")
                    .foregroundStyle(.orange)
                VStack(alignment: .leading, spacing: 2) {
                    Text("export.watermark.title").font(.subheadline.weight(.semibold))
                    Text("export.watermark.subtitle").font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.caption).foregroundStyle(.secondary)
            }
            .padding(14)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
        .foregroundStyle(.primary)
    }

    private var actions: some View {
        VStack(spacing: 12) {
            Button {
                Task { await vm.saveToPhotos(resolution: resolution, watermark: watermark) }
            } label: {
                HStack {
                    if vm.isExporting {
                        ProgressView().tint(.white)
                    } else {
                        Label("export.save", systemImage: "square.and.arrow.down")
                    }
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .foregroundStyle(.white)
                .background(Color("AccentColor").gradient, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .disabled(vm.isExporting)

            if let rendered {
                ShareLink(
                    item: Image(uiImage: rendered),
                    preview: SharePreview("ShotFrame", image: Image(uiImage: rendered))
                ) {
                    Label("export.share", systemImage: "square.and.arrow.up")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
        }
    }

    private func toast(_ message: String) -> some View {
        Label(message, systemImage: "checkmark.circle.fill")
            .font(.subheadline.weight(.medium))
            .padding(.horizontal, 18).padding(.vertical, 12)
            .background(.regularMaterial, in: Capsule())
            .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
            .padding(.bottom, 24)
            .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    /// Identity for the render `task` so it re-runs on resolution / entitlement change.
    private struct ExportKey: Equatable {
        let resolution: ExportResolution
        let isPro: Bool
    }
}
