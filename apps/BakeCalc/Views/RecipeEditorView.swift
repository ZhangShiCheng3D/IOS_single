//
//  RecipeEditorView.swift
//  BakeCalc
//
//  配方编辑器（专业版）。新建或修改配方：命名、设置份数、增删原料。
//  原料以「克」为基准存储，便于后续按份数无损缩放。
//

import SwiftUI
import SwiftData

struct RecipeEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    /// 传入 nil 表示新建。
    let recipe: SavedRecipe?

    @State private var name: String = ""
    @State private var servingsText: String = "4"
    @State private var notes: String = ""
    @State private var draftIngredients: [DraftIngredient] = []
    @State private var saveError: String?

    /// 编辑中的原料草稿（含名称与克数文本）。
    private struct DraftIngredient: Identifiable {
        let id = UUID()
        var name: String
        var gramsText: String
    }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("recipes.editor.basic") {
                    TextField("recipes.editor.name", text: $name)
                    HStack {
                        Text("recipes.editor.servings")
                        Spacer()
                        TextField("4", text: $servingsText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                    }
                }

                Section {
                    ForEach($draftIngredients) { $item in
                        HStack(spacing: 10) {
                            TextField("recipes.editor.ingredient_name", text: $item.name)
                            TextField("0", text: $item.gramsText)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 64)
                            Text("g").foregroundStyle(.secondary)
                        }
                    }
                    .onDelete { draftIngredients.remove(atOffsets: $0) }

                    Button {
                        draftIngredients.append(.init(name: "", gramsText: ""))
                    } label: {
                        Label("recipes.editor.add_ingredient", systemImage: "plus.circle.fill")
                    }
                } header: {
                    Text("recipes.editor.ingredients")
                } footer: {
                    Text("recipes.editor.ingredients_footer")
                }

                Section("recipes.editor.notes") {
                    TextField("recipes.editor.notes_placeholder", text: $notes, axis: .vertical)
                        .lineLimit(2...5)
                }
            }
            .navigationTitle(Text(recipe == nil ? "recipes.editor.new" : "recipes.editor.edit"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.save") { save() }
                        .disabled(!isValid)
                }
            }
            .onAppear(perform: loadIfNeeded)
            .alert(
                Text("common.notice"),
                isPresented: Binding(
                    get: { saveError != nil },
                    set: { if !$0 { saveError = nil } }
                )
            ) {
                Button("common.ok", role: .cancel) { saveError = nil }
            } message: {
                Text(saveError ?? "")
            }
        }
    }

    // MARK: - 载入与保存

    private func loadIfNeeded() {
        guard let recipe, draftIngredients.isEmpty, name.isEmpty else {
            if draftIngredients.isEmpty && recipe == nil {
                draftIngredients = [.init(name: "", gramsText: "")]
            }
            return
        }
        name = recipe.name
        servingsText = String(recipe.baseServings)
        notes = recipe.notes
        draftIngredients = recipe.ingredients
            .sorted { $0.order < $1.order }
            .map { .init(name: $0.name, gramsText: NumberFormatting.formatted($0.grams, maxFraction: 1)) }
        if draftIngredients.isEmpty {
            draftIngredients = [.init(name: "", gramsText: "")]
        }
    }

    private func save() {
        let servings = Int(NumberFormatting.parse(servingsText) ?? 4)
        let validDrafts = draftIngredients.filter {
            !$0.name.trimmingCharacters(in: .whitespaces).isEmpty
        }

        let target: SavedRecipe
        if let recipe {
            target = recipe
            // 清除旧原料后重建，保持顺序与数据一致。
            for old in recipe.ingredients {
                modelContext.delete(old)
            }
            target.ingredients = []
        } else {
            target = SavedRecipe(name: name, baseServings: servings)
            modelContext.insert(target)
        }

        target.name = name.trimmingCharacters(in: .whitespaces)
        target.baseServings = max(1, servings)
        target.notes = notes
        target.updatedAt = .now

        for (index, draft) in validDrafts.enumerated() {
            let grams = NumberFormatting.parse(draft.gramsText) ?? 0
            let ingredient = SavedIngredient(
                name: draft.name.trimmingCharacters(in: .whitespaces),
                grams: grams,
                order: index,
                recipe: target
            )
            modelContext.insert(ingredient)
            target.ingredients.append(ingredient)
        }

        do {
            try modelContext.save()
            Haptics.success()
            dismiss()
        } catch {
            // 保存失败时不关闭页面，保留用户输入，并向用户明确提示。
            Haptics.error()
            saveError = String(
                format: NSLocalizedString("recipes.editor.save_error", comment: ""),
                error.localizedDescription
            )
        }
    }
}

#Preview("配方编辑器") {
    RecipeEditorView(recipe: nil)
        .modelContainer(for: [SavedRecipe.self, SavedIngredient.self], inMemory: true)
}
