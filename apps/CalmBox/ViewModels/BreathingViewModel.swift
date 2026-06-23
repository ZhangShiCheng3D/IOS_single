//
//  BreathingViewModel.swift
//  CalmBox
//
//  4-7-8 呼吸法引导逻辑：吸气 4 秒 → 屏息 7 秒 → 呼气 8 秒，循环。
//

import Foundation
import SwiftUI
import Observation

@Observable
@MainActor
final class BreathingViewModel {

    /// 呼吸阶段。
    enum Phase: CaseIterable {
        case inhale     // 吸气
        case hold       // 屏息
        case exhale     // 呼气

        /// 阶段时长（秒），4-7-8 法。
        var duration: TimeInterval {
            switch self {
            case .inhale: return 4
            case .hold: return 7
            case .exhale: return 8
            }
        }

        var titleKey: LocalizedStringKey {
            switch self {
            case .inhale: return "breathing.inhale"
            case .hold: return "breathing.hold"
            case .exhale: return "breathing.exhale"
            }
        }

        /// 引导圆的目标缩放比例。
        var targetScale: CGFloat {
            switch self {
            case .inhale: return 1.0
            case .hold: return 1.0
            case .exhale: return 0.4
            }
        }

        var next: Phase {
            switch self {
            case .inhale: return .hold
            case .hold: return .exhale
            case .exhale: return .inhale
            }
        }
    }

    private(set) var phase: Phase = .inhale
    private(set) var isRunning = false
    private(set) var completedCycles = 0
    /// 当前阶段剩余秒数（向上取整用于显示）。
    private(set) var secondsRemaining: Int = Int(Phase.inhale.duration)

    /// 圆的缩放，绑定到视图动画。
    var circleScale: CGFloat = 0.4

    private var task: Task<Void, Never>?
    var onPhaseChange: ((Phase) -> Void)?

    func start() {
        guard !isRunning else { return }
        isRunning = true
        phase = .inhale
        completedCycles = 0
        runLoop()
    }

    func stop() {
        isRunning = false
        task?.cancel()
        task = nil
        withAnimation(.easeInOut(duration: 0.5)) {
            circleScale = 0.4
        }
    }

    private func runLoop() {
        task?.cancel()
        task = Task { [weak self] in
            guard let self else { return }
            while self.isRunning && !Task.isCancelled {
                await self.runPhase(self.phase)
                guard self.isRunning, !Task.isCancelled else { break }
                if self.phase == .exhale {
                    self.completedCycles += 1
                }
                self.phase = self.phase.next
            }
        }
    }

    private func runPhase(_ phase: Phase) async {
        onPhaseChange?(phase)

        // 触发圆的缩放动画。
        withAnimation(.easeInOut(duration: phase.duration)) {
            circleScale = phase.targetScale
        }

        // 倒计时显示。
        let total = Int(phase.duration)
        for remaining in stride(from: total, through: 1, by: -1) {
            guard isRunning, !Task.isCancelled else { return }
            secondsRemaining = remaining
            try? await Task.sleep(for: .seconds(1))
        }
    }
}
