//
//  TemplateEditorView.swift
//  IronLog
//
//  创建/编辑自定义模板：命名 + 添加动作 + 设定目标组数/次数。
//

import SwiftUI
import SwiftData

struct TemplateEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State private var name = ""
    @State private var detail = ""
    @State private var items: [DraftItem] = []
    @State private var showPicker = false

    /// 编辑中的草稿动作项（先在内存编排，保存时落库）。
    struct DraftItem: Identifiable {
        let id = UUID()
        let exerciseID: String
        let exerciseName: String
        var sets: Int
        var reps: Int
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && !items.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("templates.field.name") {
                    TextField("templates.field.name", text: $name)
                    TextField("templates.field.detail", text: $detail, axis: .vertical)
                        .lineLimit(1...3)
                }

                Section("templates.plan") {
                    ForEach($items) { $item in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(item.exerciseName)
                                .font(.body.weight(.medium))
                            HStack {
                                Stepper("\(String(localized: "stat.sets")): \(item.sets)", value: $item.sets, in: 1...20)
                                    .font(.subheadline)
                            }
                            HStack {
                                Stepper("\(String(localized: "set.col.reps")): \(item.reps)", value: $item.reps, in: 1...50)
                                    .font(.subheadline)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .onDelete { items.remove(atOffsets: $0) }
                    .onMove { items.move(fromOffsets: $0, toOffset: $1) }

                    Button {
                        showPicker = true
                    } label: {
                        Label("workout.add.exercise", systemImage: "plus")
                    }
                    .tint(.ironAccent)
                }
            }
            .navigationTitle("templates.new")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.save") { save() }
                        .disabled(!canSave)
                        .fontWeight(.semibold)
                }
                ToolbarItem(placement: .topBarLeading) {
                    if !items.isEmpty { EditButton() }
                }
            }
            .sheet(isPresented: $showPicker) {
                ExercisePickerView { exercise in
                    items.append(DraftItem(
                        exerciseID: exercise.id,
                        exerciseName: exercise.name,
                        sets: 3,
                        reps: 8
                    ))
                }
            }
        }
    }

    private func save() {
        let template = WorkoutTemplate(
            name: name.trimmingCharacters(in: .whitespaces),
            detail: detail,
            isBuiltIn: false
        )
        context.insert(template)
        for (index, item) in items.enumerated() {
            let te = TemplateExercise(
                exerciseID: item.exerciseID,
                exerciseName: item.exerciseName,
                order: index,
                targetSets: item.sets,
                targetReps: item.reps
            )
            te.template = template
            context.insert(te)
        }
        try? context.save()
        dismiss()
    }
}

#Preview {
    TemplateEditorView()
        .modelContainer(PreviewData.container)
}
