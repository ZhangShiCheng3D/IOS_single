//
//  ActiveWorkoutView.swift
//  IronLog
//
//  进行中训练界面。按动作分组展示组列表，提供极速录入：
//  - 一键「+组」复制上一组
//  - 行内编辑重量/次数/RPE
//  - 勾选完成自动启动休息计时并评估 PR
//

import SwiftUI
import SwiftData

struct ActiveWorkoutView: View {
    @EnvironmentObject private var activeWorkout: ActiveWorkoutViewModel
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var purchaseManager: PurchaseManager
    @Environment(\.modelContext) private var context

    @State private var showExercisePicker = false
    @State private var showFinishConfirm = false
    @State private var showDiscardConfirm = false
    @State private var showPaywall = false
    @State private var elapsedTick = Date()

    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        Group {
            if let session = activeWorkout.session {
                content(for: session)
            }
        }
        .sheet(isPresented: $showExercisePicker) {
            ExercisePickerView { exercise in
                activeWorkout.addExercise(exercise)
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }

    @ViewBuilder
    private func content(for session: WorkoutSession) -> some View {
        let groups = session.setsGrouped()

        List {
            // 顶部摘要
            Section {
                liveHeader(for: session)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color.clear)
            }

            // 各动作分组
            ForEach(groups, id: \.exercise.id) { group in
                ExerciseSection(
                    exercise: group.exercise,
                    sets: group.sets.sorted { $0.order < $1.order }
                )
            }

            // 添加动作
            Section {
                Button {
                    showExercisePicker = true
                } label: {
                    Label("workout.add.exercise", systemImage: "plus.circle.fill")
                        .font(.body.weight(.semibold))
                }
                .tint(.ironAccent)
            }
        }
        .listStyle(.insetGrouped)
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle(session.name.isEmpty ? String(localized: "workout.active") : session.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("workout.discard", role: .destructive) {
                    showDiscardConfirm = true
                }
                .tint(.red)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("workout.finish") {
                    showFinishConfirm = true
                }
                .fontWeight(.bold)
                .tint(.ironAccent)
            }
        }
        .confirmationDialog("workout.finish.confirm", isPresented: $showFinishConfirm, titleVisibility: .visible) {
            Button("workout.finish") { finish(session) }
            Button("common.cancel", role: .cancel) {}
        }
        .confirmationDialog("workout.discard.confirm", isPresented: $showDiscardConfirm, titleVisibility: .visible) {
            Button("workout.discard", role: .destructive) {
                Haptics.warning()
                activeWorkout.discardWorkout()
            }
            Button("common.cancel", role: .cancel) {}
        }
    }

    /// 实时头部：时长 + 容量 + 组数。
    private func liveHeader(for session: WorkoutSession) -> some View {
        HStack(spacing: 0) {
            headerItem(
                icon: "clock.fill",
                value: Fmt.duration(session.duration),
                label: String(localized: "stat.duration")
            )
            Divider().frame(height: 36)
            headerItem(
                icon: "scalemass.fill",
                value: Fmt.volume(session.totalVolume, unit: settings.weightUnit),
                label: String(localized: "stat.volume")
            )
            Divider().frame(height: 36)
            headerItem(
                icon: "checkmark.circle.fill",
                value: "\(session.completedSetCount)",
                label: String(localized: "stat.sets")
            )
        }
        .padding(.vertical, 12)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
        // 依赖 ticker 每秒刷新时长显示。
        .id(elapsedTick)
        .onReceive(ticker) { elapsedTick = $0 }
    }

    private func headerItem(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 3) {
            Label(value, systemImage: icon)
                .font(.subheadline.weight(.bold).monospacedDigit())
                .labelStyle(.titleAndIcon)
                .foregroundStyle(Color.ironAccent)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func finish(_ session: WorkoutSession) {
        // 免费版训练次数限制。
        let completedCount = completedSessionCount()
        if !purchaseManager.isPro && completedCount >= AppSettings.freeWorkoutLimit {
            showPaywall = true
            return
        }
        Haptics.success()
        activeWorkout.finishWorkout(syncHealthKit: settings.syncToHealthKit)
    }

    private func completedSessionCount() -> Int {
        let descriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate { $0.endDate != nil }
        )
        return (try? context.fetchCount(descriptor)) ?? 0
    }
}

/// 单个动作的分组：标题 + 各组行 + 加组按钮。
private struct ExerciseSection: View {
    let exercise: Exercise
    let sets: [SetEntry]

    @EnvironmentObject private var activeWorkout: ActiveWorkoutViewModel

    var body: some View {
        Section {
            // 列标题
            HStack {
                Text("set.col.set").frame(width: 36, alignment: .leading)
                Text("set.col.weight").frame(maxWidth: .infinity, alignment: .leading)
                Text("set.col.reps").frame(width: 64, alignment: .leading)
                Text("set.col.rpe").frame(width: 52, alignment: .leading)
                Spacer().frame(width: 28)
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
            .listRowSeparator(.hidden)

            ForEach(Array(sets.enumerated()), id: \.element.id) { index, set in
                SetRowView(set: set, displayIndex: index + 1)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            activeWorkout.deleteSet(set)
                        } label: {
                            Label("common.delete", systemImage: "trash")
                        }
                    }
            }

            Button {
                addSet()
            } label: {
                Label("set.add", systemImage: "plus")
                    .font(.subheadline.weight(.medium))
            }
            .tint(.ironAccent)
        } header: {
            HStack {
                Text(exercise.name)
                    .font(.headline)
                    .textCase(nil)
                Spacer()
                MuscleChip(group: exercise.muscleGroup)
            }
        }
    }

    private func addSet() {
        // 复制本动作最后一组，最快路径；无组则加空组。
        if let last = sets.last {
            _ = activeWorkout.duplicateSet(last)
        } else {
            activeWorkout.addExercise(exercise)
        }
    }
}

#Preview("进行中训练") {
    let vm = ActiveWorkoutViewModel()
    vm.configure(context: PreviewData.container.mainContext)
    if !vm.isWorkoutActive {
        vm.startEmptyWorkout(name: "推日")
        vm.addExercise(PreviewData.sampleExercise)
    }
    return NavigationStack {
        ActiveWorkoutView()
    }
    .environmentObject(AppSettings())
    .environmentObject(PurchaseManager())
    .environmentObject(vm)
    .environmentObject(RestTimerViewModel())
    .modelContainer(PreviewData.container)
}
