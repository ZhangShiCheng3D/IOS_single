//
//  ActiveWorkoutViewModel.swift
//  IronLog
//
//  当前进行中训练的状态机：创建/恢复会话、添加动作与组、完成组（触发 PR）、
//  快速复制上一组、结束训练并可选写入 HealthKit。
//
//  录入速度是核心竞争力——这里的方法都为「最少点击完成一组」而设计。
//

import SwiftUI
import SwiftData

@MainActor
final class ActiveWorkoutViewModel: ObservableObject {

    /// 当前进行中的训练（nil 表示无进行中训练）。
    @Published private(set) var session: WorkoutSession?
    /// 最近一次刷新 PR 的组 ID（用于一次性高亮动画）。
    @Published var lastPRSetID: UUID?

    private var context: ModelContext?

    func configure(context: ModelContext) {
        self.context = context
        // 恢复未结束的训练（崩溃/退出后再进入仍能续练）。
        if session == nil {
            let descriptor = FetchDescriptor<WorkoutSession>(
                predicate: #Predicate { $0.endDate == nil },
                sortBy: [SortDescriptor(\.date, order: .reverse)]
            )
            session = (try? context.fetch(descriptor))?.first
        }
    }

    var isWorkoutActive: Bool { session != nil }

    // MARK: - 会话生命周期

    /// 开始一次空白训练。
    func startEmptyWorkout(name: String = "") {
        guard let context else { return }
        let new = WorkoutSession(name: name)
        context.insert(new)
        try? context.save()
        session = new
    }

    /// 基于模板开始训练，自动填入计划动作（按目标组数生成空组）。
    func startFromTemplate(_ template: WorkoutTemplate) {
        guard let context else { return }
        let new = WorkoutSession(name: template.name, templateName: template.name)
        context.insert(new)

        var order = 0
        for item in template.orderedExercises {
            guard let exercise = fetchExercise(id: item.exerciseID) else { continue }
            for _ in 0..<max(1, item.targetSets) {
                let set = SetEntry(
                    order: order,
                    reps: item.targetReps,
                    exercise: exercise
                )
                set.session = new
                context.insert(set)
                order += 1
            }
        }
        try? context.save()
        session = new
    }

    /// 结束训练。空训练（无任何组）则直接删除。
    func finishWorkout(syncHealthKit: Bool) {
        guard let context, let session else { return }
        if session.sets.isEmpty {
            context.delete(session)
        } else {
            session.endDate = .now
            if syncHealthKit {
                Task { await HealthKitManager.shared.save(session: session) }
            }
        }
        try? context.save()
        self.session = nil
    }

    /// 放弃训练（删除整次记录）。
    func discardWorkout() {
        guard let context, let session else { return }
        context.delete(session)
        try? context.save()
        self.session = nil
    }

    // MARK: - 动作与组操作

    /// 向当前训练加入一个动作，并自动追加首个空组。
    func addExercise(_ exercise: Exercise) {
        guard let context, let session else { return }
        let set = SetEntry(order: nextOrder(), exercise: exercise)
        set.session = session
        // 智能预填：取该动作历史最近一组作为起点，省去重复输入。
        if let last = lastSet(for: exercise) {
            set.weight = last.weight
            set.reps = last.reps
        }
        context.insert(set)
        try? context.save()
    }

    /// 复制某组为新的一组（最快录入路径：上一组重量/次数照搬）。
    @discardableResult
    func duplicateSet(_ set: SetEntry) -> SetEntry? {
        guard let context, let session, let exercise = set.exercise else { return nil }
        let copy = SetEntry(
            order: nextOrder(),
            weight: set.weight,
            reps: set.reps,
            rpe: set.rpe,
            isWarmup: set.isWarmup,
            exercise: exercise
        )
        copy.session = session
        context.insert(copy)
        try? context.save()
        return copy
    }

    /// 删除一组。
    func deleteSet(_ set: SetEntry) {
        guard let context else { return }
        context.delete(set)
        try? context.save()
    }

    /// 切换完成状态；首次完成时评估 PR。
    func toggleComplete(_ set: SetEntry) {
        guard let context else { return }
        set.isCompleted.toggle()
        set.timestamp = .now
        if set.isCompleted {
            let broken = PRTracker.evaluate(set: set, in: context)
            if !broken.isEmpty {
                lastPRSetID = set.id
            }
        }
        try? context.save()
    }

    // MARK: - 辅助

    private func nextOrder() -> Int {
        (session?.sets.map(\.order).max() ?? -1) + 1
    }

    private func fetchExercise(id: String) -> Exercise? {
        guard let context else { return nil }
        let descriptor = FetchDescriptor<Exercise>(predicate: #Predicate { $0.id == id })
        return (try? context.fetch(descriptor))?.first
    }

    /// 取该动作最近一次（任意历史训练）的最后一组，用于预填。
    /// 直接走关系而非谓词，避免对可选 to-one 关系做谓词链式判断。
    private func lastSet(for exercise: Exercise) -> SetEntry? {
        exercise.setEntries
            .filter { $0.isCompleted }
            .max { $0.timestamp < $1.timestamp }
    }
}
