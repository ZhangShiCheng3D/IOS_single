//
//  ExerciseDetailView.swift
//  IronLog
//
//  动作详情：基础信息 + 个人纪录 + 估算 1RM 趋势图（Pro 解锁趋势）。
//

import SwiftUI
import SwiftData
import Charts

struct ExerciseDetailView: View {
    @Bindable var exercise: Exercise

    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var purchaseManager: PurchaseManager
    @Environment(\.modelContext) private var context

    @Query private var allSessions: [WorkoutSession]
    @State private var records: [PersonalRecord] = []
    @State private var showPaywall = false

    init(exercise: Exercise) {
        self.exercise = exercise
        // 只取已完成训练，内存内再按是否包含该动作筛选（关系谓词在 SwiftData 中较弱）。
        _allSessions = Query(
            filter: #Predicate<WorkoutSession> { $0.endDate != nil },
            sort: \WorkoutSession.date
        )
    }

    private var sessionsWithExercise: [WorkoutSession] {
        allSessions.filter { session in
            session.sets.contains { $0.exercise?.id == exercise.id }
        }
    }

    private var trend: [TrendPoint] {
        StatsCalculator.oneRMTrend(exerciseID: exercise.id, sessions: sessionsWithExercise)
    }

    var body: some View {
        List {
            infoSection
            prSection
            trendSection
            if !exercise.notes.isEmpty {
                Section("exercise.field.notes") {
                    Text(exercise.notes)
                        .font(.callout)
                }
            }
        }
        .navigationTitle(exercise.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    exercise.isFavorite.toggle()
                    try? context.save()
                } label: {
                    Image(systemName: exercise.isFavorite ? "star.fill" : "star")
                        .foregroundStyle(.yellow)
                }
            }
        }
        .sheet(isPresented: $showPaywall) { PaywallView() }
        .onAppear { records = PRTracker.records(for: exercise.id, in: context) }
    }

    private var infoSection: some View {
        Section {
            HStack {
                Label {
                    Text(LocalizedStringKey(exercise.muscleGroup.localizedNameKey))
                } icon: {
                    Image(systemName: exercise.muscleGroup.systemImage)
                        .foregroundStyle(Color(exercise.muscleGroup.accentColorName))
                }
                Spacer()
                Text(LocalizedStringKey(exercise.equipment.localizedNameKey))
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var prSection: some View {
        Section("exercise.records") {
            if records.isEmpty {
                Text("exercise.records.empty")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(records) { record in
                    HStack {
                        Label {
                            Text(LocalizedStringKey(record.type.localizedNameKey))
                                .font(.subheadline)
                        } icon: {
                            Image(systemName: record.type.systemImage)
                                .foregroundStyle(Color.ironAccent)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 1) {
                            Text(valueText(for: record))
                                .font(.body.weight(.semibold).monospacedDigit())
                            Text(Fmt.date(record.date))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var trendSection: some View {
        Section {
            if !purchaseManager.isPro {
                ProLockedRow(feature: String(localized: "exercise.trend")) {
                    showPaywall = true
                }
            } else if trend.count < 2 {
                Text("exercise.trend.empty")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            } else {
                Chart(trend) { point in
                    LineMark(
                        x: .value("date", point.date),
                        y: .value("1rm", settings.weightUnit.display(fromKg: point.value))
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(Color.ironAccent)

                    PointMark(
                        x: .value("date", point.date),
                        y: .value("1rm", settings.weightUnit.display(fromKg: point.value))
                    )
                    .foregroundStyle(Color.ironAccent)
                }
                .frame(height: 200)
                .chartYAxisLabel(settings.weightUnit.symbol)
            }
        } header: {
            Text("exercise.trend")
        } footer: {
            if purchaseManager.isPro && trend.count >= 2 {
                Text("exercise.trend.footer")
            }
        }
    }

    private func valueText(for record: PersonalRecord) -> String {
        switch record.type {
        case .maxReps:
            return "\(record.reps) \(String(localized: "unit.reps"))"
        case .maxWeight, .estimatedOneRM, .maxVolume:
            return "\(Fmt.weight(record.weight, unit: settings.weightUnit)) × \(record.reps)"
        }
    }
}

/// Pro 功能锁定行。
struct ProLockedRow: View {
    let feature: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "lock.fill")
                    .foregroundStyle(Color.ironAccent)
                VStack(alignment: .leading, spacing: 2) {
                    Text("pro.locked.title")
                        .font(.subheadline.weight(.semibold))
                    Text(String(format: String(localized: "pro.locked.desc"), feature))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        ExerciseDetailView(exercise: PreviewData.sampleExercise)
    }
    .environmentObject(AppSettings())
    .environmentObject(PurchaseManager())
    .modelContainer(PreviewData.container)
}
