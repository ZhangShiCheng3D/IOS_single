//
//  ScanFlowView.swift
//  DocScanPro
//
//  扫描流程容器：调起 VisionKit 相机 → 保存页面 → 按权益触发本地 OCR。
//  免费用户可扫描与导出；OCR 与批量为专业版功能。
//

import SwiftUI
import SwiftData

struct ScanFlowView: View {

    /// 目标文件夹（从文件夹内发起扫描时传入）。
    let targetFolder: Folder?

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var purchaseManager: PurchaseManager
    @EnvironmentObject private var appSettings: AppSettings

    @StateObject private var viewModel = ScanWorkflowViewModel()

    /// 处理阶段。
    @State private var phase: Phase = .scanning
    @State private var isShowingPaywall = false

    /// 免费版单次扫描页数上限；批量扫描为专业版功能。
    private let freePageLimit = 1

    enum Phase {
        case scanning
        case processing
        case done(ScanDocument)
    }

    var body: some View {
        Group {
            switch phase {
            case .scanning:
                scannerLayer
            case .processing:
                processingLayer
            case .done(let document):
                ScanResultView(document: document) {
                    dismiss()
                }
            }
        }
        .sheet(isPresented: $isShowingPaywall) {
            PaywallView()
        }
        .alert(
            "common.error",
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )
        ) {
            Button("common.ok", role: .cancel) { dismiss() }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    // MARK: - Layers

    private var scannerLayer: some View {
        DocumentScannerView(
            onComplete: handleScanned,
            onCancel: { dismiss() },
            onError: { _ in dismiss() }
        )
        .ignoresSafeArea()
    }

    private var processingLayer: some View {
        VStack(spacing: 20) {
            ProgressView(value: viewModel.ocrProgress ?? 0)
                .progressViewStyle(.linear)
                .frame(width: 220)
            Text(viewModel.statusMessage ?? NSLocalizedString("scan.saving", comment: ""))
                .font(.headline)
            Text("scan.processing.privacyNote")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }

    // MARK: - Logic

    private func handleScanned(_ images: [UIImage]) {
        // 批量扫描为专业版功能：免费版仅保留首页，并在保存后引导升级，
        // 而非静默丢弃多余页面。
        var pagesToSave = images
        let trimmedForBatchLimit = !purchaseManager.isUnlocked(.batchScan) && images.count > freePageLimit
        if trimmedForBatchLimit {
            pagesToSave = Array(images.prefix(freePageLimit))
        }

        phase = .processing
        Task {
            // OCR 仅对专业版开启；同时尊重用户的自动 OCR 设置。
            let canOCR = purchaseManager.isUnlocked(.ocr) && appSettings.autoRunOCR

            let document = await viewModel.saveScannedImages(
                pagesToSave,
                context: modelContext,
                folder: targetFolder,
                runOCR: canOCR,
                jpegQuality: appSettings.jpegQuality
            )

            if let document {
                phase = .done(document)
                // 因免费版页数上限被裁剪：在结果页之上弹出付费墙，告知批量扫描为专业版功能。
                if trimmedForBatchLimit {
                    isShowingPaywall = true
                }
            } else if viewModel.errorMessage == nil {
                // 无错误（例如用户取消或空结果）才直接关闭；有错误时由 alert 关闭。
                dismiss()
            }
        }
    }
}

#Preview {
    ScanFlowView(targetFolder: nil)
        .environmentObject(PurchaseManager.shared)
        .environmentObject(AppSettings())
        .modelContainer(PreviewData.container)
}
