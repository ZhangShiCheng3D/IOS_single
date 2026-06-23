//
//  HapticManager.swift
//  CalmBox
//
//  基于 Core Haptics 的触觉反馈引擎。
//  提供预设的细腻震动模式（泡泡破裂、陀螺旋转、呼吸引导等），
//  并在不支持 Core Haptics 的设备上优雅降级到 UIFeedbackGenerator。
//

import Foundation
import CoreHaptics
import UIKit
import Observation

@Observable
final class HapticManager {

    /// 当前设备是否支持 Core Haptics。
    private(set) var supportsHaptics: Bool = CHHapticEngine.capabilitiesForHardware().supportsHaptics

    /// 用户是否启用触觉反馈（从设置同步）。
    var isEnabled: Bool = true

    private var engine: CHHapticEngine?

    // 降级方案使用的轻量级生成器。
    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private let rigidImpact = UIImpactFeedbackGenerator(style: .rigid)

    // MARK: - 生命周期

    /// 预热触觉引擎，应在 App 启动后尽早调用。
    func prepare() {
        guard supportsHaptics else { return }
        do {
            engine = try CHHapticEngine()
            engine?.isAutoShutdownEnabled = true

            // 引擎被系统中断后自动重启（来电、后台等场景）。
            engine?.stoppedHandler = { [weak self] _ in
                self?.restartEngine()
            }
            engine?.resetHandler = { [weak self] in
                self?.restartEngine()
            }
            try engine?.start()
        } catch {
            // 引擎不可用时关闭高级触觉，回退到基础反馈。
            supportsHaptics = false
            engine = nil
        }
    }

    private func restartEngine() {
        guard supportsHaptics else { return }
        do {
            try engine?.start()
        } catch {
            supportsHaptics = false
        }
    }

    // MARK: - 预设模式

    /// 泡泡破裂：短促、清脆、带轻微衰减的"啵"感。
    func playBubblePop() {
        guard isEnabled else { return }
        guard supportsHaptics, let engine else {
            rigidImpact.impactOccurred(intensity: 0.9)
            return
        }

        let events = [
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.85)
                ],
                relativeTime: 0
            ),
            // 极短的余韵，让"破"感更立体。
            CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.35),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
                ],
                relativeTime: 0.02,
                duration: 0.08
            )
        ]
        play(events: events, on: engine)
    }

    /// 陀螺旋转时的持续摩擦感，强度随转速变化。
    /// - Parameter intensity: 0...1，对应转速归一化值。
    func playSpinTick(intensity: Float) {
        guard isEnabled else { return }
        let clamped = max(0.0, min(1.0, intensity))
        guard supportsHaptics, let engine else {
            if clamped > 0.5 { lightImpact.impactOccurred(intensity: CGFloat(clamped)) }
            return
        }

        let event = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: clamped * 0.7),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2)
            ],
            relativeTime: 0
        )
        play(events: [event], on: engine)
    }

    /// 呼吸引导：一段平滑渐强或渐弱的连续震动。
    /// - Parameters:
    ///   - duration: 阶段时长（秒）。
    ///   - rising: true 表示吸气（渐强），false 表示呼气（渐弱）。
    func playBreathing(duration: TimeInterval, rising: Bool) {
        guard isEnabled, supportsHaptics, let engine else { return }

        let start: Float = rising ? 0.05 : 0.6
        let end: Float = rising ? 0.6 : 0.05

        let event = CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [
                // 起始强度即曲线起点；后续由 intensityControl 曲线平滑过渡。
                CHHapticEventParameter(parameterID: .hapticIntensity, value: start),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.1)
            ],
            relativeTime: 0,
            duration: duration
        )

        let curve = CHHapticParameterCurve(
            parameterID: .hapticIntensityControl,
            controlPoints: [
                .init(relativeTime: 0, value: start),
                .init(relativeTime: duration, value: end)
            ],
            relativeTime: 0
        )

        do {
            let pattern = try CHHapticPattern(events: [event], parameterCurves: [curve])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            // 单次播放失败可忽略，不影响整体体验。
        }
    }

    /// 通用成功反馈（购买完成、计时结束等）。
    func playSuccess() {
        guard isEnabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    /// 轻触选择反馈。
    func playSelection() {
        guard isEnabled else { return }
        UISelectionFeedbackGenerator().selectionChanged()
    }

    // MARK: - 私有

    private func play(events: [CHHapticEvent], on engine: CHHapticEngine) {
        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            // 播放失败时回退到基础反馈，避免完全无感。
            mediumImpact.impactOccurred()
        }
    }
}
