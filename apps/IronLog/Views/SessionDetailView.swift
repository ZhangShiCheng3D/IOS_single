//
//  SessionDetailView.swift
//  IronLog
//
//  历史训练详情：摘要 + 按动作展开的各组明细。可编辑备注。
//

import SwiftUI
import SwiftData

struct SessionDetailView: View {
    @Bindable var session: WorkoutSession
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.modelContext) private var context

    var body: some View {
        List {
            Section {
                SessionSummaryCard(session: session)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }

            ForEach(session.setsGrouped(), id: \.exercise.id) { group in
                Section {
                    ForEach(Array(group.sets.sorted { $0.order < $1.order }.enumerated()), id: \.element.id) { index, set in
                        HStack {
                            if set.isWarmup {
                                Image(systemName: "flame.fill").foregroundStyle(.orange)
                            } else {
                                Text("\(index + 1)")
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text("\(Fmt.weight(set.weight, unit: settings.weightUnit)) × \(set.reps)")
                                .font(.body.monospacedDigit())
                            if set.rpe > 0 {
                                Text("RPE \(Fmt.weight(set.rpe))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .font(.subheadline)
                    }
                } header: {
                    HStack {
                        Text(group.exercise.name).textCase(nil)
                        Spacer()
                        MuscleChip(group: group.exercise.muscleGroup)
                    }
                }
            }

            Section("workout.notes") {
                TextField("workout.notes.placeholder", text: $session.notes, axis: .vertical)
                    .lineLimit(2...8)
                    .onChange(of: session.notes) { _, _ in try? context.save() }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(session.name.isEmpty ? String(localized: "workout.untitled") : session.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        SessionDetailView(session: PreviewData.sampleSession)
    }
    .environmentObject(AppSettings())
    .modelContainer(PreviewData.container)
}
