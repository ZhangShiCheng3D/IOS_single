//
//  ScanResultView.swift
//  DocScanPro
//
//  扫描完成后的结果预览：展示页数、首页缩略图，提供导出 PDF / 查看详情 / 继续扫描。
//

import SwiftUI
import SwiftData

struct ScanResultView: View {

    let document: ScanDocument
    /// 完成回调（关闭整个扫描流程）。
    var onDone: () -> Void

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appSettings: AppSettings
    @StateObject private var viewModel = DocumentDetailViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                successHeader
                thumbnailStrip
                Spacer()
                actionButtons
            }
            .padding(24)
            .navigationTitle("scan.result.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("common.done", action: onDone)
                        .fontWeight(.semibold)
                }
            }
            .sheet(item: Binding(
                get: { viewModel.shareURL.map(IdentifiableURL.init) },
                set: { viewModel.shareURL = $0?.url }
            )) { item in
                ShareSheet(items: [item.url])
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
        .onAppear { Haptics.success() }
    }

    private var successHeader: some View {
        VStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(.green)
                .accessibilityHidden(true)
            Text("scan.result.saved")
                .font(.title2.bold())
            Text(String(format: NSLocalizedString("scan.result.pageCount", comment: ""), document.pageCount))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 16)
    }

    private var thumbnailStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(Array(document.orderedPages.enumerated()), id: \.element.id) { index, page in
                    if let image = UIImage(data: page.imageData) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 110, height: 150)
                            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous)
                                    .stroke(Color(.separator), lineWidth: 0.5)
                            )
                            .accessibilityLabel(Text(String(format: NSLocalizedString("scan.result.pageThumbnail", comment: ""), index + 1)))
                    }
                }
            }
            .padding(.horizontal, 4)
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                Task {
                    await viewModel.exportPDF(
                        for: document,
                        includeTextLayer: appSettings.includeTextLayerInPDF
                    )
                }
            } label: {
                Label("scan.result.exportPDF", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.isExporting)

            NavigationLink {
                DocumentDetailView(document: document)
            } label: {
                Label("scan.result.viewDetail", systemImage: "doc.text.magnifyingglass")
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
            }
            .buttonStyle(.bordered)
        }
    }
}

/// 包装 URL 使其可用于 .sheet(item:)。
struct IdentifiableURL: Identifiable {
    let url: URL
    var id: String { url.absoluteString }
    init(_ url: URL) { self.url = url }
}

#Preview {
    ScanResultView(document: PreviewData.sampleDocument, onDone: {})
        .environmentObject(AppSettings())
        .modelContainer(PreviewData.container)
}
