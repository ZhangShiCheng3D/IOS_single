//
//  TemplatesView.swift
//  IronLog
//
//  训练模板：内置 5/3/1、PPL、上/下肢、全身等，亦可自建。
//  点击「开始」直接以模板开练。
//

import SwiftUI
import SwiftData

struct TemplatesView: View {
    @EnvironmentObject private var activeWorkout: ActiveWorkoutViewModel
    @Environment(\.modelContext) private var context

    @Query(sort: [SortDescriptor(\WorkoutTemplate.createdAt)])
    private var templates: [WorkoutTemplate]

    @State private var showCreate = false

    private var builtIn: [WorkoutTemplate] { templates.filter(\.isBuiltIn) }
    private var custom: [WorkoutTemplate] { templates.filter { !$0.isBuiltIn } }

    var body: some View {
        NavigationStack {
            List {
                if !custom.isEmpty {
                    Section("templates.custom") {
                        ForEach(custom) { template in
                            templateLink(template)
                        }
                        .onDelete { offsets in
                            for i in offsets { context.delete(custom[i]) }
                            try? context.save()
                        }
                    }
                }

                Section("templates.builtin") {
                    ForEach(builtIn) { template in
                        templateLink(template)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("tab.templates")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showCreate = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showCreate) {
                TemplateEditorView()
            }
        }
    }

    private func templateLink(_ template: WorkoutTemplate) -> some View {
        NavigationLink {
            TemplateDetailView(template: template)
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(template.name)
                    .font(.body.weight(.semibold))
                if !template.detail.isEmpty {
                    Text(template.detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                Text("\(template.exercises.count) \(String(localized: "stat.exercises"))")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 2)
        }
    }
}

#Preview {
    TemplatesView()
        .environmentObject(ActiveWorkoutViewModel())
        .modelContainer(PreviewData.container)
}
