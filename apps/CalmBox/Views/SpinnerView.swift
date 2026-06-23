//
//  SpinnerView.swift
//  CalmBox
//
//  解压陀螺：拖动旋转，松手后按物理摩擦衰减自转，伴随触觉与音效。
//

import SwiftUI

struct SpinnerView: View {

    @Environment(HapticManager.self) private var haptics
    @State private var viewModel = SpinnerViewModel()

    /// 上一次拖动的角度与时间，用于计算角速度。
    @State private var lastAngle: Double?
    @State private var lastTime: Date?

    private let accent = Theme.Scene.accent(.spinner)

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            GeometryReader { geo in
                let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
                let size = min(geo.size.width, geo.size.height) * 0.8

                spinner(size: size)
                    .position(center)
                    .gesture(rotationGesture(center: center))
            }
            .frame(height: 320)

            speedIndicator

            Text("spinner.hint")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding()
        .navigationTitle("scene.spinner.title")
        .navigationBarTitleDisplayMode(.inline)
        .sceneBackground(.spinner)
        .onAppear {
            viewModel.onTick = { speed in
                haptics.playSpinTick(intensity: Float(speed))
                SoundEffectPlayer.shared.play(.spinTick, volume: Float(0.2 + speed * 0.5),
                                              rate: Float(0.8 + speed * 0.8))
            }
        }
        .onDisappear { viewModel.stop() }
    }

    // MARK: - 陀螺图形

    private func spinner(size: CGFloat) -> some View {
        ZStack {
            // 外圈光晕
            Circle()
                .fill(
                    RadialGradient(colors: [accent.opacity(0.5), .clear],
                                   center: .center, startRadius: size * 0.3, endRadius: size * 0.7)
                )
                .frame(width: size * 1.3, height: size * 1.3)

            // 陀螺主体（三叶造型）
            ForEach(0..<3) { i in
                Capsule()
                    .fill(
                        LinearGradient(colors: Theme.Scene.gradient(.spinner),
                                       startPoint: .top, endPoint: .bottom)
                    )
                    .frame(width: size * 0.42, height: size)
                    .rotationEffect(.degrees(Double(i) * 120))
            }

            // 中心轴承
            Circle()
                .fill(.white)
                .frame(width: size * 0.28, height: size * 0.28)
                .overlay(Circle().stroke(accent, lineWidth: 3))
                .shadow(radius: 4)

            Image(systemName: "asterisk")
                .font(.system(size: size * 0.12, weight: .bold))
                .foregroundStyle(accent)
        }
        .frame(width: size, height: size)
        .rotationEffect(.degrees(viewModel.angle))
        .shadow(color: accent.opacity(0.4), radius: 12)
        .accessibilityLabel("spinner.a11y")
        .accessibilityHint("spinner.hint")
    }

    private var speedIndicator: some View {
        HStack(spacing: 8) {
            Image(systemName: "gauge.with.dots.needle.bottom.50percent")
                .foregroundStyle(accent)
            ProgressView(value: viewModel.normalizedSpeed)
                .tint(accent)
                .frame(maxWidth: 200)
        }
        .accessibilityHidden(true)
    }

    // MARK: - 手势

    private func rotationGesture(center: CGPoint) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let angle = angleFromCenter(center: center, point: value.location)
                let now = Date()
                if let last = lastAngle, let lastT = lastTime {
                    var delta = angle - last
                    // 处理跨越 ±180 度的跳变。
                    if delta > 180 { delta -= 360 }
                    if delta < -180 { delta += 360 }
                    let dt = now.timeIntervalSince(lastT)
                    viewModel.drag(deltaAngle: delta, deltaTime: max(dt, 0.001))
                }
                lastAngle = angle
                lastTime = now
            }
            .onEnded { _ in
                viewModel.release(withVelocity: viewModel.angularVelocity)
                lastAngle = nil
                lastTime = nil
            }
    }

    /// 计算触点相对中心的角度（度）。
    private func angleFromCenter(center: CGPoint, point: CGPoint) -> Double {
        let dx = point.x - center.x
        let dy = point.y - center.y
        return atan2(dy, dx) * 180 / .pi
    }
}

#Preview {
    NavigationStack {
        SpinnerView()
            .environment(HapticManager())
    }
}
