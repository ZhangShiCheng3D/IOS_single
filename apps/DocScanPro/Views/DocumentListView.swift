//
//  DocumentListView.swift
//  DocScanPro
//
//  文档库主界面：列表展示所有扫描文档，支持搜索、收藏筛选、删除。
//

import SwiftUI
import SwiftData

struct DocumentListView: View {

    /// 发起扫描的回调（由 ContentView 提供）。
    var onScan: () -> Void

    @Environment(\.modelContext) private var modelContext

    /// 按更新时间倒序查询全部文档。
    @Query(sort: \ScanDocument.updatedAt, order: .reverse)
    private var documents: [ScanDocument]

    @State private var searchText = ""
    @State private var showFavoritesOnly = false

    /// 经搜索与筛选后的文档。
    private var filteredDocuments: [ScanDocument] {
        documents.filter { document in
            (!showFavoritesOnly || document.isFavorite) && document.matches(query: searchText)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if documents.isEmpty {
                    EmptyStateView(
                        systemImage: "doc.text.viewfinder",
                        titleKey: "documents.empty.title",
                        messageKey: "documents.empty.message",
                        actionTitle: "documents.empty.action",
                        action: onScan
                    )
                } else if filteredDocuments.isEmpty {
                    EmptyStateView(
                        systemImage: "magnifyingglass",
                        titleKey: "documents.noResults.title",
                        messageKey: "documents.noResults.message"
                    )
                } else {
                    documentList
                }
            }
            .navigationTitle("tab.library")
            .searchable(text: $searchText, prompt: Text("documents.search.prompt"))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        withAnimation { showFavoritesOnly.toggle() }
                    } label: {
                        Image(systemName: showFavoritesOnly ? "star.fill" : "star")
                    }
                    .accessibilityLabel(Text("documents.filter.favorites"))
                }
            }
        }
    }

    private var documentList: some View {
        List {
            ForEach(filteredDocuments) { document in
                NavigationLink {
                    DocumentDetailView(document: document)
                } label: {
                    DocumentRowView(document: document)
                }
                .swipeActions(edge: .leading) {
                    Button {
                        toggleFavorite(document)
                    } label: {
                        Label("documents.favorite", systemImage: document.isFavorite ? "star.slash" : "star")
                    }
                    .tint(.yellow)
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        delete(document)
                    } label: {
                        Label("common.delete", systemImage: "trash")
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private func toggleFavorite(_ document: ScanDocument) {
        withAnimation(DS.Motion.snappy) { document.isFavorite.toggle() }
        document.updatedAt = .now
        Haptics.selectionChanged()
        try? modelContext.save()
    }

    private func delete(_ document: ScanDocument) {
        withAnimation { modelContext.delete(document) }
        Haptics.tapMedium()
        try? modelContext.save()
    }
}

#Preview {
    DocumentListView(onScan: {})
        .modelContainer(PreviewData.container)
}
