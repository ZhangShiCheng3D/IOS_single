//
//  RestTimerViewModel.swift
//  IronLog
//
//  组间休息计时器。支持后台继续（基于绝对结束时间计算剩余），
//  结束时本地通知提醒。
//

import SwiftUI
import Combine

@MainActor
final class RestTimerViewModel: ObservableObject {

    /// 是否正在计时。
    @Published private(set) var isRunning = false
    /// 剩余秒数（用于显示）。
    @Published private(set) var remaining: TimeInterval = 0
    /// 本轮总时长。
    @Published private(set) var total: TimeInterval = 0

    /// 计时绝对结束时间——后台返回后据此重算，保证准确。
    private var endTime: Date?
    private var timer: AnyCancellable?

    /// 进度 0...1（用于环形进度）。
    var progress: Double {
        guard total > 0 else { return 0 }
        return min(1, max(0, 1 - remaining / total))
    }

    /// 开始一段休息。
    func start(seconds: Int) {
        let duration = TimeInterval(seconds)
        total = duration
        remaining = duration
        endTime = Date().addingTimeInterval(duration)
        isRunning = true
        NotificationManager.shared.scheduleRestFinished(after: duration)
        startTicking()
    }

    /// 增减时长（±15s 快捷键）。
    func adjust(by delta: TimeInterval) {
        guard isRunning, let end = endTime else { return }
        let newEnd = end.addingTimeInterval(delta)
        // 不允许调成已过去的时间。
        endTime = max(newEnd, Date().addingTimeInterval(1))
        total = max(1, total + delta)
        recalculate()
        // 重新安排通知。
        NotificationManager.shared.cancelRest()
        NotificationManager.shared.scheduleRestFinished(after: remaining)
    }

    /// 停止/跳过。
    func stop() {
        isRunning = false
        timer?.cancel()
        timer = nil
        endTime = nil
        remaining = 0
        NotificationManager.shared.cancelRest()
    }

    /// 从后台恢复时重算（在 scenePhase 变为 active 时调用）。
    func refreshFromBackground() {
        guard isRunning else { return }
        recalculate()
    }

    // MARK: - 私有

    private func startTicking() {
        timer?.cancel()
        timer = Timer.publish(every: 0.2, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.recalculate()
            }
    }

    private func recalculate() {
        guard let end = endTime else { return }
        remaining = max(0, end.timeIntervalSinceNow)
        if remaining <= 0 {
            // 结束。
            isRunning = false
            timer?.cancel()
            timer = nil
            endTime = nil
            // 触觉反馈。
            Haptics.success()
        }
    }
}
