//
//  ExportSheet.swift
//  PixelStudio
//
//  导出：PNG（当前帧）/ GIF（动画，Pro）。可选放大倍数，支持系统分享与
//  保存到相册。全部本地完成。
//

import SwiftUI
import Photos

struct ExportSheet: View {
    @ObservedObject var vm: EditorViewModel
    @EnvironmentObject private var purchaseManager: PurchaseManager
    @Environment(\.dismiss) private var dismiss

    enum Format: String, CaseIterable, Identifiable {
        case png, gif
        var id: String { rawValue }
        var label: String { rawValue.uppercased() }
    }

    @State private var format: Format = .png
    @State private var scale: Int = 8
    @State private var exportedURL: URL?
    @State private var errorMessage: String?
    @State private var isExporting = false
    @State private var saveResult: String?
    @State private var showingPaywall = false

    private let scaleOptions = [1, 4, 8, 16, 32]

    var body: some View {
        NavigationStack {
            Form {
                formatSection
                scaleSection
                previewSection
                actionSection
                if let saveResult {
                    Section { Text(saveResult).font(.footnote).foregroundStyle(.secondary) }
                }
            }
            .navigationTitle("export.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.close") { dismiss() }
                }
            }
            .alert("export.failed", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } })) {
                Button("common.ok", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "")
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView(highlightedFeature: .gifExport)
            }
        }
    }

    // MARK: - Sections

    private var formatSection: some View {
        Section("export.format") {
            Picker("export.format", selection: $format) {
                ForEach(Format.allCases) { fmt in
                    Text(fmt.label).tag(fmt)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: format) { _, newValue in
                if newValue == .gif && !purchaseManager.isProUnlocked {
                    format = .png
                    showingPaywall = true
                }
            }

            if format == .gif {
                Label("export.gif.hint", systemImage: "info.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var scaleSection: some View {
        Section("export.scale") {
            Picker("export.scale", selection: $scale) {
                ForEach(scaleOptions, id: \.self) { s in
                    Text("\(s)×").tag(s)
                }
            }
            .pickerStyle(.segmented)
            Text("\(vm.width * scale) × \(vm.height * scale) px")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var previewSection: some View {
        Section {
            ZStack {
                CheckerboardBackground(cell: 12)
                if let cg = vm.image(forFrame: vm.currentFrameIndex) {
                    Image(decorative: cg, scale: 1, orientation: .up)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                }
            }
            .frame(height: 160)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private var actionSection: some View {
        Section {
            if let url = exportedURL {
                ShareLink(item: url) {
                    Label("export.share", systemImage: "square.and.arrow.up")
                }
                Button {
                    saveToPhotos(url: url)
                } label: {
                    Label("export.saveToPhotos", systemImage: "photo.on.rectangle")
                }
            }

            Button {
                runExport()
            } label: {
                HStack {
                    if isExporting { ProgressView() }
                    Text(exportedURL == nil ? "export.generate" : "export.regenerate")
                }
            }
            .disabled(isExporting)
        }
    }

    // MARK: - 导出逻辑

    private func runExport() {
        isExporting = true
        saveResult = nil
        Task {
            do {
                let data: Data
                let fileName: String
                switch format {
                case .png:
                    data = try vm.exportCurrentFramePNG(scale: scale)
                    fileName = "\(sanitizedName)-\(vm.currentFrameIndex + 1).png"
                case .gif:
                    data = try vm.exportGIF(scale: scale)
                    fileName = "\(sanitizedName).gif"
                }
                let url = try ImageExporter.writeTemporary(data, fileName: fileName)
                await MainActor.run {
                    exportedURL = url
                    isExporting = false
                    AppHaptics.success()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isExporting = false
                    AppHaptics.error()
                }
            }
        }
    }

    private func saveToPhotos(url: URL) {
        // 使用 async PhotoKit API：闭包仅捕获 Sendable 的 url，不再捕获非 Sendable
        // 的 View（self），满足 Swift 6 严格并发；Task 继承 View 的 MainActor 隔离，
        // saveResult 始终在主线程更新。
        Task {
            let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
            guard status == .authorized || status == .limited else {
                saveResult = NSLocalizedString("export.photos.denied", comment: "")
                AppHaptics.error()
                return
            }
            do {
                try await PHPhotoLibrary.shared().performChanges {
                    let request = PHAssetCreationRequest.forAsset()
                    request.addResource(with: .photo, fileURL: url, options: nil)
                }
                saveResult = NSLocalizedString("export.photos.saved", comment: "")
                AppHaptics.success()
            } catch {
                saveResult = error.localizedDescription
                AppHaptics.error()
            }
        }
    }

    private var sanitizedName: String {
        let base = vm.projectName.trimmingCharacters(in: .whitespaces)
        return base.isEmpty ? "PixelStudio" : base
    }
}

#Preview {
    let container = PreviewData.container
    let project = PreviewData.sampleProject(in: container)
    return ExportSheet(vm: EditorViewModel(project: project, context: container.mainContext))
        .environmentObject(PurchaseManager())
}
