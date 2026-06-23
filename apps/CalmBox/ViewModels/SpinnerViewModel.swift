//
//  SpinnerViewModel.swift
//  CalmBox
//
//  解压陀螺物理逻辑：拖动赋予角速度，松手后按摩擦力衰减自转。
//

import Foundation
import SwiftUI
import Observation

@Observable
@MainActor
final class SpinnerViewModel {

    /// 当前旋转角度（度）。
    private(set) var angle: Double = 0
    /// 当前角速度（度/秒）。
    private(set) var angularVelocity: Double = 0

    /// 摩擦系数（每帧衰减比例）。每秒约衰减到 (friction^60)。
    private let friction: Double = 0.99
    /// 视为停止的速度阈值。
    private let stopThreshold: Double = 5

    private var displayLinkTask: Task<Void, Never>?
    private var lastTickAngle: Double = 0

    /// 归一化转速 0...1，用于驱动触觉强度。
    var normalizedSpeed: Double {
        min(1.0, abs(angularVelocity) / 1440.0)  // 1440 度/秒 (4转/秒) 视为满速
    }

    var isSpinning: Bool { abs(angularVelocity) > stopThreshold }

    /// 每越过一定角度触发一次触觉的回调。
    var onTick: ((Double) -> Void)?

    /// 拖动手势更新：根据角度变化设置即时角速度。
    func drag(deltaAngle: Double, deltaTime: Double) {
        angle += deltaAngle
        if deltaTime > 0 {
            angularVelocity = deltaAngle / deltaTime
        }
    }

    /// 松手时给予一个甩动初速度。
    func release(withVelocity velocity: Double) {
        angularVelocity = velocity
        startDecay()
    }

    /// 点击轻拨：施加一个固定冲量。
    func flick() {
        angularVelocity += 720  // 额外 2 转/秒
        startDecay()
    }

    func stop() {
        angularVelocity = 0
        displayLinkTask?.cancel()
        displayLinkTask = nil
    }

    /// 启动衰减循环（约 60fps）。
    private func startDecay() {
        displayLinkTask?.cancel()
        lastTickAngle = angle
        displayLinkTask = Task { [weak self] in
            guard let self else { return }
            let frameInterval: Double = 1.0 / 60.0
            while !Task.isCancelled {
                guard self.isSpinning else {
                    self.angularVelocity = 0
                    break
                }
                self.angle += self.angularVelocity * frameInterval
                self.angularVelocity *= self.friction

                // 每旋转约 30 度触发一次触觉，强度随转速。
                if abs(self.angle - self.lastTickAngle) >= 30 {
                    self.lastTickAngle = self.angle
                    self.onTick?(self.normalizedSpeed)
                }

                try? await Task.sleep(for: .seconds(frameInterval))
            }
        }
    }
}
