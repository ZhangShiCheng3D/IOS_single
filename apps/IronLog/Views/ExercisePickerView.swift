//
//  ExercisePickerView.swift
//  IronLog
//
//  选择动作加入训练。支持搜索 + 肌群筛选 + 收藏置顶，
//  亦可现场创建自定义动作。
//

import SwiftUI
import SwiftData

struct ExercisePickerView: View {
    /// 选中回调。
    let onSelect: (Exercise) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @Query(sort: [SortDescriptor(\Exercise.name)]) private var exercises: [Exercise]

    @State private var searchText = ""
    @State private var selectedGroup: MuscleGroup?
    @State private var showAddCustom = false

    private var filtered: [Exercise] {
        exercises.filter { ex in
            let matchesGroup = selectedGroup == nil || ex.muscleGroup == selectedGroup
            let matchesSearch = searchText.isEmpty
                || ex.name.localizedCaseInsensitiveContains(searchText)
                || ex.nameEN.localizedCaseInsensitiveContains(searchText)
            return matchesGroup && matchesSearch
        }
        .sorted { lhs, rhs in
            if lhs.isFavorite != rhs.isFavorite { return lhs.isFavorite }
            return lhs.name < rhs.name
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                groupFilter
                List {
                    ForEach(filtered) { exercise in
                        Button {
                            onSelect(exercise)
                            dismiss()
                        } label: {
                            ExerciseRow(exercise: exercise)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .listStyle(.plain)
                .overlay {
                    if filtered.isEmpty {
                        ContentUnavailableView.search(text: searchText)
                    }
                }
            }
            .searchable(text: $searchText, prompt: Text("exercise.search"))
            .navigationTitle("workout.add.exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAddCustom = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddCustom) {
                AddExerciseView { newExercise in
                    onSelect(newExercise)
                    dismiss()
                }
            }
        }
    }

    /// 横向肌群筛选条。
    private var groupFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(title: String(localized: "filter.all"), isSelected: selectedGroup == nil) {
                    selectedGroup = nil
                }
                ForEach(MuscleGroup.allCases) { group in
                    FilterChip(
                        title: String(localized: String.LocalizationValue(group.localizedNameKey)),
                        isSelected: selectedGroup == group
                    ) {
                        selectedGroup = selectedGroup == group ? nil : group
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color(.systemGroupedBackground))
    }
}

/// 筛选胶囊按钮。
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(
                    isSelected ? Color.ironAccent : Color(.secondarySystemGroupedBackground),
                    in: Capsule()
                )
                .foregroundStyle(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }
}

/// 动作列表行。
struct ExerciseRow: View {
    let exercise: Exercise

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: exercise.muscleGroup.systemImage)
                .font(.title3)
                .foregroundStyle(Color(exercise.muscleGroup.accentColorName))
                .frame(width: 36, height: 36)
                .background(Color(exercise.muscleGroup.accentColorName).opacity(0.15), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(exercise.name)
                        .font(.body.weight(.medium))
                    if exercise.isCustom {
                        Image(systemName: "person.crop.circle")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                Text(LocalizedStringKey(exercise.equipment.localizedNameKey))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if exercise.isFavorite {
                Image(systemName: "star.fill")
                    .font(.caption)
                    .foregroundStyle(.yellow)
            }
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
    }
}

#Preview {
    ExercisePickerView { _ in }
        .modelContainer(PreviewData.container)
}
