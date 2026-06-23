//
//  MeditationViewModel.swift
//  CalmBox
//
//  冥想计时器逻辑：选择时长、倒计时、完成后写入 SwiftData 记录。
//

import Foundation
import SwiftUI
import SwiftData
import Observation

@Observable
@MainActor
final class MeditationViewModel {

    /// 预设时长选项（分钟）。
    static let durationOptions: [Int] = [3, 5, 10, 15, 20, 30]

    /// 选中的时长（分钟）。
    var selectedMinutes: Int = 10

    private(set) var isRunning = false
    private(set) var isPaused = false
    /// 剩余秒数。
    private(set) var secondsRemaining: Int = 0
    /// 完成进度 0...1。
    private(set) var progress: Double = 0

    private var totalSeconds: Int = 0
    private var elapsedSeconds: Int = 0
    private var task: Task<Void, Never>?
    private var startDate: Date = .now

    /// 计时结束回调。
    var onFinished: (() -> Void)?

    /// 剩余时间格式化字符串 mm:ss。
    var displayTime: String {
        let minutes = secondsRemaining / 60
        let seconds = secondsRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    func start() {
        guard !isRunning else { return }
        totalSeconds = selectedMinutes * 60
        secondsRemaining = totalSeconds
        elapsedSeconds = 0
        progress = 0
        isRunning = true
        isPaused = false
        startDate = .now
        runTimer()
    }

    func togglePause() {
        guard isRunning else { return }
        isPaused.toggle()
        if isPaused {
            task?.cancel()
        } else {
            runTimer()
        }
    }

    /// 停止计时。返回本次会话记录（若需要持久化）。
    @discardableResult
    func stop(completed: Bool) -> MeditationSession {
        isRunning = false
        isPaused = false
        task?.cancel()
        task = nil

        let session = MeditationSession(
            plannedDuration: TimeInterval(totalSeconds),
            completedDuration: TimeInterval(elapsedSeconds),
            isCompleted: completed,
            startedAt: startDate
        )
        return session
    }

    private func runTimer() {
        task?.cancel()
        task = Task { [weak self] in
            guard let self else { return }
            while self.isRunning && !self.isPaused && !Task.isCancelled {
                guard self.secondsRemaining > 0 else {
                    self.finish()
                    break
                }
                try? await Task.sleep(for: .seconds(1))
                guard self.isRunning, !self.isPaused, !Task.isCancelled else { break }
                self.secondsRemaining -= 1
                self.elapsedSeconds += 1
                self.progress = self.totalSeconds > 0
                    ? Double(self.elapsedSeconds) / Double(self.totalSeconds)
                    : 0
            }
        }
    }

    private func finish() {
        progress = 1
        isRunning = false
        onFinished?()
    }

    /// 将会话持久化到 SwiftData。
    func persist(_ session: MeditationSession, in context: ModelContext) {
        context.insert(session)
        try? context.save()
    }
}
