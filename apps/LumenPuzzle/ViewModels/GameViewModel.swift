//
//  GameViewModel.swift
//  LumenPuzzle
//
//  单关游玩的视图模型（MVVM）。
//  持有 SceneKit 控制器，驱动计时、步数统计、照亮判定与通关流程。
//

import Foundation
import SwiftData
import SceneKit
import Combine

@MainActor
final class GameViewModel: ObservableObject {

    let level: Level
    let scene: PuzzleSceneController

    // MARK: - 发布给视图的状态

    /// 已点亮目标数。
    @Published private(set) var litCount: Int = 0
    /// 目标总数。
    @Published private(set) var totalCount: Int = 0
    /// 是否已解开本关。
    @Published private(set) var isSolved: Bool = false
    /// 已用时（秒）。
    @Published private(set) var elapsedSeconds: Double = 0
    /// 移动步数（每次拖动结束计一次）。
    @Published private(set) var moveCount: Int = 0
    /// 是否展示通关结算面板。
    @Published var showCompletion: Bool = false
    /// 本次通关新解锁的成就。
    @Published private(set) var newlyUnlockedAchievements: [Achievement] = []
    /// 是否显示提示。
    @Published var showHint: Bool = false

    // MARK: - 私有

    private var context: ModelContext?
    private var timer: AnyCancellable?
    private var startDate: Date?
    /// 防止在一次连续拖动中重复计步。
    private var isDragging = false

    init(level: Level) {
        self.level = level
        self.scene = PuzzleSceneController(level: level)
        self.totalCount = level.targets.count
        self.litCount = scene.litTargetIDs.count
    }

    /// 注入 SwiftData 上下文（视图出现后调用）。
    func configure(context: ModelContext) {
        self.context = context
    }

    // MARK: - 计时

    /// 开始本关计时。
    func start() {
        guard startDate == nil else { return }
        startDate = .now
        timer = Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                // Timer 在主线程投递，断言主 actor 隔离后安全访问状态。
                MainActor.assumeIsolated {
                    guard let self, let start = self.startDate, !self.isSolved else { return }
                    self.elapsedSeconds = Date.now.timeIntervalSince(start)
                }
            }
    }

    private func stopTimer() {
        timer?.cancel()
        timer = nil
    }

    // MARK: - 交互

    /// 开始一次拖动。
    func beginDrag() {
        guard !isSolved else { return }
        isDragging = true
    }

    /// 拖动过程中：移动光源到指定平面坐标，并实时更新照亮状态。
    func dragLight(toPlanePoint point: SCNVector3) {
        guard !isSolved else { return }
        let previousLit = litCount
        scene.moveLight(toPlanePoint: point)
        litCount = scene.litTargetIDs.count
        // 新点亮一个目标时给出轻触反馈。
        if litCount > previousLit {
            Haptics.tick()
        }
    }

    /// 结束一次拖动：计步并检查是否通关。
    func endDrag() {
        guard isDragging else { return }
        isDragging = false
        guard !isSolved else { return }
        moveCount += 1
        checkForCompletion()
    }

    /// 相机环绕（两指拖动）。
    func orbitCamera(deltaYaw: Float, deltaPitch: Float) {
        scene.orbit(deltaYaw: deltaYaw, deltaPitch: deltaPitch)
    }

    // MARK: - 通关

    private func checkForCompletion() {
        let result = scene.evaluateLitState()
        litCount = result.litCount
        guard result.isSolved else { return }

        isSolved = true
        stopTimer()
        Haptics.success()
        scene.playCompletionFlourish()

        if let context {
            let service = ProgressService(context: context)
            newlyUnlockedAchievements = service.recordCompletion(
                level: level,
                timeSeconds: elapsedSeconds,
                moves: moveCount
            )
        }

        // 略作停顿，让庆祝动画先呈现，再弹出结算。
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) { [weak self] in
            MainActor.assumeIsolated {
                self?.showCompletion = true
            }
        }
    }

    /// 格式化用时显示。
    var formattedTime: String {
        let total = Int(elapsedSeconds)
        return String(format: "%02d:%02d", total / 60, total % 60)
    }
}
