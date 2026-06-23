//
//  FolderListView.swift
//  DocScanPro
//
//  文件夹管理：创建/删除文件夹，进入文件夹查看其下文档。
//

import SwiftUI
import SwiftData

struct FolderListView: View {

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Folder.createdAt, order: .reverse) private var folders: [Folder]

    @State private var isShowingNewFolder = false
    @State private var newFolderName = ""

    var body: some View {
        NavigationStack {
            Group {
                if folders.isEmpty {
                    EmptyStateView(
                        systemImage: "folder.badge.plus",
                        titleKey: "folders.empty.title",
                        messageKey: "folders.empty.message",
                        actionTitle: "folders.new",
                        action: { isShowingNewFolder = true }
                    )
                } else {
                    folderList
                }
            }
            .navigationTitle("tab.folders")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        newFolderName = ""
                        isShowingNewFolder = true
                    } label: {
                        Image(systemName: "folder.badge.plus")
                    }
                    .accessibilityLabel(Text("folders.new"))
                }
            }
            .alert("folders.new", isPresented: $isShowingNewFolder) {
                TextField("folders.new.placeholder", text: $newFolderName)
                Button("common.cancel", role: .cancel) {}
                Button("common.create") { createFolder() }
            }
        }
    }

    private var folderList: some View {
        List {
            ForEach(folders) { folder in
                NavigationLink {
                    FolderDetailView(folder: folder)
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: folder.symbolName)
                            .font(.title2)
                            .foregroundStyle(Color.accentColor)
                            .frame(width: 34)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(folder.name)
                                .font(.body)
                            Text(String(format: NSLocalizedString("folders.count", comment: ""), folder.documentCount))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .onDelete(perform: deleteFolders)
        }
        .listStyle(.insetGrouped)
    }

    private func createFolder() {
        let name = newFolderName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        let folder = Folder(name: name)
        modelContext.insert(folder)
        try? modelContext.save()
    }

    private func deleteFolders(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(folders[index])
        }
        try? modelContext.save()
    }
}

/// 文件夹详情：展示该文件夹下的文档。
struct FolderDetailView: View {
    @Bindable var folder: Folder

    var body: some View {
        Group {
            if folder.documents.isEmpty {
                EmptyStateView(
                    systemImage: "doc.text",
                    titleKey: "folders.detail.empty.title",
                    messageKey: "folders.detail.empty.message"
                )
            } else {
                List {
                    ForEach(folder.documents.sorted { $0.updatedAt > $1.updatedAt }) { document in
                        NavigationLink {
                            DocumentDetailView(document: document)
                        } label: {
                            DocumentRowView(document: document)
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle(folder.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    FolderListView()
        .modelContainer(PreviewData.container)
}
