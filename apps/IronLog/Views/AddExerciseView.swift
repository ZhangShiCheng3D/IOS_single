//
//  AddExerciseView.swift
//  IronLog
//
//  创建自定义动作。
//

import SwiftUI
import SwiftData

struct AddExerciseView: View {
    /// 创建完成回调（可选：用于选择器直接选中新动作）。
    var onCreate: ((Exercise) -> Void)?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State private var name = ""
    @State private var muscleGroup: MuscleGroup = .chest
    @State private var equipment: Equipment = .barbell
    @State private var notes = ""

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("exercise.field.name") {
                    TextField("exercise.field.name", text: $name)
                }
                Section("exercise.field.muscle") {
                    Picker("exercise.field.muscle", selection: $muscleGroup) {
                        ForEach(MuscleGroup.allCases) { group in
                            Text(LocalizedStringKey(group.localizedNameKey)).tag(group)
                        }
                    }
                    .pickerStyle(.navigationLink)
                }
                Section("exercise.field.equipment") {
                    Picker("exercise.field.equipment", selection: $equipment) {
                        ForEach(Equipment.allCases) { eq in
                            Text(LocalizedStringKey(eq.localizedNameKey)).tag(eq)
                        }
                    }
                    .pickerStyle(.navigationLink)
                }
                Section("exercise.field.notes") {
                    TextField("exercise.field.notes.placeholder", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("exercise.new")
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
            }
        }
    }

    private func save() {
        let exercise = Exercise(
            name: name.trimmingCharacters(in: .whitespaces),
            muscleGroup: muscleGroup,
            equipment: equipment,
            notes: notes,
            isCustom: true
        )
        context.insert(exercise)
        try? context.save()
        onCreate?(exercise)
        dismiss()
    }
}

#Preview {
    AddExerciseView()
        .modelContainer(PreviewData.container)
}
