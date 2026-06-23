//
//  TemplateDetailView.swift
//  IronLog
//
//  模板详情：展示计划动作与处方，提供「开始训练」与「复制为自定义」。
//

import SwiftUI
import SwiftData

struct TemplateDetailView: View {
    let template: WorkoutTemplate

    @EnvironmentObject private var activeWorkout: ActiveWorkoutViewModel
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var showActiveConflict = false

    var body: some View {
        List {
            if !template.detail.isEmpty {
                Section {
                    Text(template.detail)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }

            Section("templates.plan") {
                ForEach(template.orderedExercises) { item in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.exerciseName)
                                .font(.body.weight(.medium))
                            if !item.prescription.isEmpty {
                                Text(item.prescription)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        Text("\(item.targetSets) × \(item.targetReps)")
                            .font(.subheadline.monospacedDigit().weight(.semibold))
                            .foregroundStyle(Color.ironAccent)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(template.name)
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 10) {
                Button {
                    startWorkout()
                } label: {
                    Label("templates.start", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                        .fontWeight(.bold)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(.ironAccent)

                Button {
                    duplicateAsCustom()
                } label: {
                    Label("templates.duplicate", systemImage: "doc.on.doc")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
            .padding()
            .background(.regularMaterial)
        }
        .alert("templates.conflict.title", isPresented: $showActiveConflict) {
            Button("templates.conflict.replace", role: .destructive) {
                activeWorkout.discardWorkout()
                activeWorkout.startFromTemplate(template)
                dismiss()
            }
            Button("common.cancel", role: .cancel) {}
        } message: {
            Text("templates.conflict.msg")
        }
    }

    private func startWorkout() {
        if activeWorkout.isWorkoutActive {
            showActiveConflict = true
        } else {
            activeWorkout.startFromTemplate(template)
            dismiss()
        }
    }

    /// 把内置模板复制成可编辑的自定义模板。
    private func duplicateAsCustom() {
        let copy = WorkoutTemplate(
            name: template.name + " " + String(localized: "templates.copy.suffix"),
            detail: template.detail,
            isBuiltIn: false
        )
        context.insert(copy)
        for item in template.orderedExercises {
            let te = TemplateExercise(
                exerciseID: item.exerciseID,
                exerciseName: item.exerciseName,
                order: item.order,
                targetSets: item.targetSets,
                targetReps: item.targetReps,
                prescription: item.prescription
            )
            te.template = copy
            context.insert(te)
        }
        try? context.save()
    }
}

#Preview {
    let template = (try? PreviewData.container.mainContext.fetch(
        FetchDescriptor<WorkoutTemplate>()
    ).first) ?? WorkoutTemplate(name: "PPL — 推")
    return NavigationStack {
        TemplateDetailView(template: template)
    }
    .environmentObject(ActiveWorkoutViewModel())
    .modelContainer(PreviewData.container)
}
