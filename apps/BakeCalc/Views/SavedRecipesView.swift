//
//  SavedRecipesView.swift
//  BakeCalc
//
//  已保存配方列表（专业版）。基于 SwiftData @Query 实时展示，
//  支持新建、编辑、删除与按名称搜索。
//

import SwiftUI
import SwiftData

struct SavedRecipesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SavedRecipe.updatedAt, order: .reverse) private var recipes: [SavedRecipe]
    @State private var searchText = ""
    @State private var editorTarget: EditorTarget?
    @State private var pendingDeletion: [SavedRecipe] = []

    /// 编辑器目标：新建或编辑现有配方。
    private enum EditorTarget: Identifiable {
        case new
        case existing(SavedRecipe)

        var id: String {
            switch self {
            case .new: return "new"
            case .existing(let recipe): return recipe.persistentModelID.hashValue.description
            }
        }
    }

    private var filteredRecipes: [SavedRecipe] {
        guard !searchText.isEmpty else { return recipes }
        return recipes.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        Group {
            if recipes.isEmpty {
                emptyState
            } else {
                recipeList
            }
        }
        .navigationTitle(Text("feature.savedRecipes"))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Haptics.tap()
                    editorTarget = .new
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel(Text("recipes.add"))
            }
        }
        .sheet(item: $editorTarget) { target in
            switch target {
            case .new:
                RecipeEditorView(recipe: nil)
            case .existing(let recipe):
                RecipeEditorView(recipe: recipe)
            }
        }
        .confirmationDialog(
            Text("recipes.delete.confirm"),
            isPresented: Binding(
                get: { !pendingDeletion.isEmpty },
                set: { if !$0 { pendingDeletion = [] } }
            ),
            titleVisibility: .visible
        ) {
            Button("recipes.delete.action", role: .destructive) {
                confirmDelete()
            }
            Button("common.cancel", role: .cancel) { pendingDeletion = [] }
        } message: {
            Text("recipes.delete.message")
        }
    }

    private var recipeList: some View {
        List {
            ForEach(filteredRecipes) { recipe in
                Button {
                    editorTarget = .existing(recipe)
                } label: {
                    recipeRow(recipe)
                }
                .buttonStyle(.plain)
            }
            .onDelete(perform: delete)
        }
        .searchable(text: $searchText, prompt: Text("recipes.search"))
    }

    private func recipeRow(_ recipe: SavedRecipe) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.bcAccent.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: "book.closed.fill")
                    .foregroundStyle(Color.bcAccent)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(recipe.name.isEmpty ? NSLocalizedString("recipes.untitled", comment: "") : recipe.name)
                    .font(.subheadline.weight(.semibold))
                Text(String(
                    format: NSLocalizedString("recipes.subtitle", comment: ""),
                    recipe.baseServings, recipe.ingredientCount
                ))
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .accessibilityHidden(true)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("recipes.empty.title", systemImage: "tray")
        } description: {
            Text("recipes.empty.message")
        } actions: {
            Button {
                editorTarget = .new
            } label: {
                Label("recipes.add", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
        }
    }

    /// 左滑删除：先收集目标，弹出确认对话框，避免误删不可恢复的配方。
    private func delete(at offsets: IndexSet) {
        Haptics.warning()
        pendingDeletion = offsets.map { filteredRecipes[$0] }
    }

    private func confirmDelete() {
        for recipe in pendingDeletion {
            modelContext.delete(recipe)
        }
        try? modelContext.save()
        pendingDeletion = []
        Haptics.success()
    }
}

#Preview("配方列表") {
    NavigationStack {
        SavedRecipesView()
    }
    .modelContainer(for: [SavedRecipe.self, SavedIngredient.self], inMemory: true)
}
