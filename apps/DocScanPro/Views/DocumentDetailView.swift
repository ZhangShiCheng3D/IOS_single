//
//  DocumentDetailView.swift
//  DocScanPro
//
//  文档详情：分页浏览扫描图像与 OCR 文本，支持导出 PDF、重跑 OCR、
//  重命名、收藏、分配文件夹/标签。OCR 相关能力受专业版权益约束。
//

import SwiftUI
import SwiftData

struct DocumentDetailView: View {

    @Bindable var document: ScanDocument

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var purchaseManager: PurchaseManager
    @EnvironmentObject private var appSettings: AppSettings

    @StateObject private var viewModel = DocumentDetailViewModel()

    @State private var selectedPageIndex = 0
    @State private var isShowingRename = false
    @State private var renameText = ""
    @State private var isShowingPaywall = false
    @State private var isShowingOrganize = false

    var body: some View {
        VStack(spacing: 0) {
            pagePager
            Divider()
            textPanel
        }
        .navigationTitle(document.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
        .overlay {
            if let progress = viewModel.ocrProgress {
                ocrOverlay(progress: progress)
            }
        }
        .sheet(item: shareBinding) { item in
            ShareSheet(items: [item.url])
        }
        .sheet(isPresented: $isShowingPaywall) {
            PaywallView()
        }
        .sheet(isPresented: $isShowingOrganize) {
            OrganizeDocumentView(document: document)
        }
        .alert("detail.rename.title", isPresented: $isShowingRename) {
            TextField("detail.rename.placeholder", text: $renameText)
            Button("common.cancel", role: .cancel) {}
            Button("common.save") {
                viewModel.rename(document, to: renameText, context: modelContext)
            }
        }
        .alert(
            "common.error",
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )
        ) {
            Button("common.ok", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    // MARK: - Page pager

    private var pagePager: some View {
        TabView(selection: $selectedPageIndex) {
            ForEach(Array(document.orderedPages.enumerated()), id: \.element.id) { index, page in
                if let image = UIImage(data: page.imageData) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .padding(DS.Spacing.sm)
                        .tag(index)
                        .accessibilityLabel(Text(String(format: NSLocalizedString("a11y.detail.page", comment: ""), index + 1, document.pageCount)))
                }
            }
        }
        .tabViewStyle(.page(indexDisplayMode: document.pageCount > 1 ? .automatic : .never))
        .frame(height: 380)
        .background(Color(.secondarySystemBackground))
    }

    // MARK: - Text panel

    private var textPanel: some View {
        Group {
            if !purchaseManager.isUnlocked(.ocr) {
                ocrLockedPanel
            } else if let page = currentPage {
                PageTextEditor(
                    page: page,
                    document: document,
                    onSave: { text in
                        viewModel.updateText(text, for: page, in: document, context: modelContext)
                    }
                )
            }
        }
        .frame(maxHeight: .infinity)
    }

    /// 未解锁 OCR 时展示的引导面板。
    private var ocrLockedPanel: some View {
        VStack(spacing: 16) {
            Image(systemName: "text.viewfinder")
                .font(.system(size: 44))
                .foregroundStyle(Color.accentColor)
                .accessibilityHidden(true)
            Text("detail.ocr.locked.title")
                .font(.headline)
            Text("detail.ocr.locked.message")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button("detail.ocr.unlock") {
                isShowingPaywall = true
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private func ocrOverlay(progress: Double) -> some View {
        ZStack {
            Color.black.opacity(0.3).ignoresSafeArea()
            VStack(spacing: 14) {
                ProgressView(value: progress)
                    .frame(width: 180)
                Text("detail.ocr.running")
                    .font(.subheadline)
            }
            .padding(24)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Button {
                    Task {
                        await viewModel.exportPDF(for: document, includeTextLayer: appSettings.includeTextLayerInPDF)
                    }
                } label: {
                    Label("detail.action.exportPDF", systemImage: "square.and.arrow.up")
                }

                Button {
                    handleOCRRequest()
                } label: {
                    Label("detail.action.runOCR", systemImage: "text.viewfinder")
                }

                Button {
                    renameText = document.title
                    isShowingRename = true
                } label: {
                    Label("detail.action.rename", systemImage: "pencil")
                }

                Button {
                    withAnimation(DS.Motion.snappy) { document.isFavorite.toggle() }
                    Haptics.selectionChanged()
                    try? modelContext.save()
                } label: {
                    // 显式声明为 LocalizedStringKey，避免三元字面量退化为不本地化的 String。
                    let favoriteKey: LocalizedStringKey = document.isFavorite ? "documents.unfavorite" : "documents.favorite"
                    Label(favoriteKey, systemImage: document.isFavorite ? "star.slash" : "star")
                }

                Button {
                    isShowingOrganize = true
                } label: {
                    Label("detail.action.organize", systemImage: "folder.badge.gearshape")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
    }

    // MARK: - Helpers

    private var currentPage: ScannedPage? {
        let pages = document.orderedPages
        guard pages.indices.contains(selectedPageIndex) else { return pages.first }
        return pages[selectedPageIndex]
    }

    private var shareBinding: Binding<IdentifiableURL?> {
        Binding(
            get: { viewModel.shareURL.map(IdentifiableURL.init) },
            set: { viewModel.shareURL = $0?.url }
        )
    }

    /// OCR 请求：未解锁则引导付费，已解锁则执行。
    private func handleOCRRequest() {
        guard purchaseManager.isUnlocked(.ocr) else {
            isShowingPaywall = true
            return
        }
        Task {
            await viewModel.rerunOCR(for: document, context: modelContext)
        }
    }
}

#Preview {
    NavigationStack {
        DocumentDetailView(document: PreviewData.sampleDocument)
    }
    .environmentObject(PurchaseManager.shared)
    .environmentObject(AppSettings())
    .modelContainer(PreviewData.container)
}
