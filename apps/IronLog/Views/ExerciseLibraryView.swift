//
//  ExerciseLibraryView.swift
//  IronLog
//
//  动作库：浏览 100+ 内置动作与自定义动作，按肌群分组、可搜索、可收藏。
//  点击进入动作详情（历史 PR + 1RM 趋势）。
//

import SwiftUI
import SwiftData

struct ExerciseLibraryView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: [SortDescriptor(\Exercise.name)]) private var exercises: [Exercise]

    @State private var searchText = ""
    @State private var selectedGroup: MuscleGroup?
    @State private var showAddCustom = false

    /// 按肌群分组（筛选后）。
    private var grouped: [(group: MuscleGroup, items: [Exercise])] {
        let filtered = exercises.filter { ex in
            let matchesGroup = selectedGroup == nil || ex.muscleGroup == selectedGroup
            let matchesSearch = searchText.isEmpty
                || ex.name.localizedCaseInsensitiveContains(searchText)
                || ex.nameEN.localizedCaseInsensitiveContains(searchText)
            return matchesGroup && matchesSearch
        }
        return MuscleGroup.allCases.compactMap { group in
            let items = filtered.filter { $0.muscleGroup == group }
                .sorted { ($0.isFavorite ? 0 : 1, $0.name) < ($1.isFavorite ? 0 : 1, $1.name) }
            return items.isEmpty ? nil : (group, items)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                groupFilter
                List {
                    ForEach(grouped, id: \.group) { section in
                        Section {
                            ForEach(section.items) { exercise in
                                NavigationLink {
                                    ExerciseDetailView(exercise: exercise)
                                } label: {
                                    ExerciseRow(exercise: exercise)
                                }
                                .swipeActions(edge: .leading) {
                                    Button {
                                        exercise.isFavorite.toggle()
                                        try? context.save()
                                    } label: {
                                        Label("exercise.favorite", systemImage: exercise.isFavorite ? "star.slash" : "star")
                                    }
                                    .tint(.yellow)
                                }
                                .swipeActions(edge: .trailing) {
                                    if exercise.isCustom {
                                        Button(role: .destructive) {
                                            context.delete(exercise)
                                            try? context.save()
                                        } label: {
                                            Label("common.delete", systemImage: "trash")
                                        }
                                    }
                                }
                            }
                        } header: {
                            Text(LocalizedStringKey(section.group.localizedNameKey))
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .overlay {
                    if grouped.isEmpty {
                        ContentUnavailableView.search(text: searchText)
                    }
                }
            }
            .searchable(text: $searchText, prompt: Text("exercise.search"))
            .navigationTitle("tab.exercises")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAddCustom = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddCustom) {
                AddExerciseView()
            }
        }
    }

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
    }
}

#Preview {
    ExerciseLibraryView()
        .environmentObject(AppSettings())
        .modelContainer(PreviewData.container)
}
