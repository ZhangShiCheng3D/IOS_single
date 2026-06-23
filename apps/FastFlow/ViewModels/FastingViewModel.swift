//
//  FastingViewModel.swift
//  FastFlow
//
//  断食计时核心逻辑：开始/结束断食、驱动 UI 走时、同步通知与 Live Activity。
//

import Foundation
import SwiftData
import Observation

@Observable
@MainActor
final class FastingViewModel {
    /// SwiftData 上下文，用于读写会话。
    private let context: ModelContext

    /// 当前进行中的会话（nil 表示未在断食）。
    private(set) var activeSession: FastingSession?

    /// 每秒刷新一次的"当前时间"，驱动进度与计时文本。
    private(set) var now: Date = .now

    /// 是否已为本次会话触发过达成提醒（避免重复 Haptics）。
    private var didFireGoalHaptic = false

    private var timer: Timer?

    init(context: ModelContext) {
        self.context = context
        loadActiveSession()
        LiveActivityManager.shared.restoreIfNeeded()
        startTickingIfNeeded()
    }

    // MARK: - 派生状态

    /// 是否正在断食。
    var isFasting: Bool { activeSession != nil }

    /// 已断食时长。
    var elapsed: TimeInterval {
        guard let session = activeSession else { return 0 }
        return max(0, now.timeIntervalSince(session.startTime))
    }

    /// 进度 0...1（clamp）。
    var progress: Double {
        guard let session = activeSession, session.targetDuration > 0 else { return 0 }
        return min(1.0, elapsed / session.targetDuration)
    }

    /// 原始进度（可超过 1），用于展示超额完成。
    var rawProgress: Double {
        guard let session = activeSession, session.targetDuration > 0 else { return 0 }
        return elapsed / session.targetDuration
    }

    /// 是否已达成目标。
    var hasReachedGoal: Bool {
        guard let session = activeSession else { return false }
        return elapsed >= session.targetDuration
    }

    /// 距目标剩余时长（达成后为 0）。
    var remaining: TimeInterval {
        guard let session = activeSession else { return 0 }
        return max(0, session.targetDuration - elapsed)
    }

    /// 计划结束时间。
    var scheduledEndTime: Date? {
        activeSession?.scheduledEndTime
    }

    // MARK: - 操作

    /// 以指定方案开始断食。
    func startFasting(plan: FastingPlan, startTime: Date = .now) {
        guard activeSession == nil else { return }

        let session = FastingSession(
            startTime: startTime,
            endTime: nil,
            targetDuration: plan.targetDuration,
            planName: plan.name
        )
        context.insert(session)
        try? context.save()

        activeSession = session
        didFireGoalHaptic = false

        // 安排目标达成通知。
        NotificationManager.shared.scheduleFastingGoalNotification(
            at: session.scheduledEndTime,
            planName: plan.name
        )
        // 启动 Live Activity。
        LiveActivityManager.shared.start(
            startTime: session.startTime,
            targetEndTime: session.scheduledEndTime,
            planName: plan.name
        )
        // 写入 Widget 共享快照。
        SharedStore.save(FastingSnapshot(
            isFasting: true,
            startTime: session.startTime,
            targetEndTime: session.scheduledEndTime,
            planName: plan.name
        ))

        Haptics.tap()
        startTickingIfNeeded()
    }

    /// 结束当前断食。
    func endFasting(at endTime: Date = .now) {
        guard let session = activeSession else { return }
        session.endTime = endTime
        try? context.save()

        NotificationManager.shared.cancelFastingGoalNotification()
        LiveActivityManager.shared.end()
        SharedStore.save(.idle)
        Haptics.success()

        activeSession = nil
        stopTicking()
    }

    /// 调整当前会话的开始时间（用户忘记开始时回填）。
    func adjustStartTime(to newStart: Date) {
        guard let session = activeSession, newStart <= .now else { return }
        session.startTime = newStart
        try? context.save()

        NotificationManager.shared.scheduleFastingGoalNotification(
            at: session.scheduledEndTime,
            planName: session.planName
        )
        LiveActivityManager.shared.start(
            startTime: session.startTime,
            targetEndTime: session.scheduledEndTime,
            planName: session.planName
        )
        SharedStore.save(FastingSnapshot(
            isFasting: true,
            startTime: session.startTime,
            targetEndTime: session.scheduledEndTime,
            planName: session.planName
        ))
    }

    // MARK: - 计时驱动

    private func startTickingIfNeeded() {
        guard activeSession != nil, timer == nil else { return }
        let timer = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        // 加入 common 模式，滚动时也持续走时。
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
        tick()
    }

    private func stopTicking() {
        timer?.invalidate()
        timer = nil
    }

    private func tick() {
        now = .now

        // 首次达成目标时反馈并刷新 Live Activity。
        if hasReachedGoal, !didFireGoalHaptic, let session = activeSession {
            didFireGoalHaptic = true
            Haptics.success()
            Task {
                await LiveActivityManager.shared.update(
                    startTime: session.startTime,
                    targetEndTime: session.scheduledEndTime,
                    planName: session.planName,
                    hasReachedGoal: true
                )
            }
        }
    }

    // MARK: - 加载

    private func loadActiveSession() {
        var descriptor = FetchDescriptor<FastingSession>(
            predicate: #Predicate { $0.endTime == nil },
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        activeSession = try? context.fetch(descriptor).first
    }

    // 注：Timer 闭包以 [weak self] 捕获，不会形成保留环；本 VM 由 ContentView 以
    // @State 持有、生命周期与 App 一致，故无需在 deinit 中清理（避免 Swift 6
    // 主线程隔离 deinit 访问隔离属性的限制）。停止断食时已在 stopTicking() 中失效。
}
