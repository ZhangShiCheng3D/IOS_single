//
//  OrganizeDocumentView.swift
//  DocScanPro
//
//  整理文档：分配文件夹、增删标签。无限文件夹/标签为专业版功能，
//  免费版限制数量。
//

import SwiftUI
import SwiftData

struct OrganizeDocumentView: View {

    @Bindable var document: ScanDocument

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var purchaseManager: PurchaseManager

    @Query(sort: \Folder.name) private var folders: [Folder]
    @Query(sort: \Tag.name) private var tags: [Tag]

    @State private var newTagName = ""
    @State private var selectedColorHex = Tag.presetColors[0]
    @State private var isShowingPaywall = false

    /// 免费版标签上限。
    private let freeTagLimit = 3

    var body: some View {
        NavigationStack {
            Form {
                folderSection
                tagSection
                addTagSection
            }
            .navigationTitle("organize.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("common.done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $isShowingPaywall) {
                PaywallView()
            }
        }
    }

    private var folderSection: some View {
        Section("organize.folder") {
            Picker("organize.folder", selection: folderSelection) {
                Text("organize.folder.none").tag(Optional<Folder>.none)
                ForEach(folders) { folder in
                    Label(folder.name, systemImage: folder.symbolName)
                        .tag(Optional(folder))
                }
            }
            .pickerStyle(.navigationLink)
        }
    }

    private var tagSection: some View {
        Section("organize.tags") {
            if tags.isEmpty {
                Text("organize.tags.empty")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(tags) { tag in
                    Button {
                        toggle(tag)
                    } label: {
                        HStack {
                            Circle().fill(tag.color).frame(width: 12, height: 12)
                            Text(tag.name)
                                .foregroundStyle(.primary)
                            Spacer()
                            if document.tags.contains(where: { $0.id == tag.id }) {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Color.accentColor)
                            }
                        }
                    }
                }
                .onDelete(perform: deleteTags)
            }
        }
    }

    private var addTagSection: some View {
        Section("organize.newTag") {
            TextField("organize.newTag.placeholder", text: $newTagName)

            // 颜色选择。
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Tag.presetColors, id: \.self) { hex in
                        Circle()
                            .fill(Color(hex: hex) ?? .accentColor)
                            .frame(width: 28, height: 28)
                            .overlay(
                                Circle().stroke(Color.primary, lineWidth: selectedColorHex == hex ? 2 : 0)
                            )
                            .onTapGesture {
                                withAnimation(DS.Motion.snappy) { selectedColorHex = hex }
                                Haptics.selectionChanged()
                            }
                    }
                }
                .padding(.vertical, 4)
            }

            Button("organize.newTag.add") {
                addTag()
            }
            .disabled(newTagName.isBlank)
        }
    }

    // MARK: - Logic

    private var folderSelection: Binding<Folder?> {
        Binding(
            get: { document.folder },
            set: { newValue in
                document.folder = newValue
                document.updatedAt = .now
                try? modelContext.save()
            }
        )
    }

    private func toggle(_ tag: Tag) {
        if let index = document.tags.firstIndex(where: { $0.id == tag.id }) {
            document.tags.remove(at: index)
        } else {
            // 免费版限制标签数量。
            if !purchaseManager.isUnlocked(.unlimitedOrganization), document.tags.count >= freeTagLimit {
                Haptics.tapMedium()
                isShowingPaywall = true
                return
            }
            document.tags.append(tag)
        }
        document.updatedAt = .now
        Haptics.selectionChanged()
        try? modelContext.save()
    }

    private func addTag() {
        let name = newTagName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        let tag = Tag(name: name, colorHex: selectedColorHex)
        modelContext.insert(tag)

        // 新建后自动关联到当前文档（这是用户的预期）；尊重免费版标签上限，
        // 超限则仅创建不关联，并引导升级。
        if purchaseManager.isUnlocked(.unlimitedOrganization) || document.tags.count < freeTagLimit {
            document.tags.append(tag)
            document.updatedAt = .now
        } else {
            isShowingPaywall = true
        }

        try? modelContext.save()
        newTagName = ""
        Haptics.selectionChanged()
    }

    /// 删除标签（从所有文档解除关联，关系规则为 .nullify）。
    private func deleteTags(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(tags[index])
        }
        document.updatedAt = .now
        try? modelContext.save()
        Haptics.tapMedium()
    }
}

#Preview {
    OrganizeDocumentView(document: PreviewData.sampleDocument)
        .environmentObject(PurchaseManager.shared)
        .modelContainer(PreviewData.container)
}
