//
//  BreathingView.swift
//  CalmBox
//
//  4-7-8 呼吸引导：随阶段缩放的引导圆 + 触觉同步，帮助入睡放松。
//

import SwiftUI

struct BreathingView: View {

    @Environment(HapticManager.self) private var haptics
    @State private var viewModel = BreathingViewModel()

    private let accent = Theme.Scene.accent(.breathing)

    var body: some View {
        ZStack {
            LinearGradient(
                colors: Theme.Scene.gradient(.breathing),
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                phaseLabel
                breathingCircle
                cycleCounter

                Spacer()

                controlButton
            }
            .padding()
        }
        .navigationTitle("scene.breathing.title")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear {
            viewModel.onPhaseChange = { phase in
                haptics.playBreathing(duration: phase.duration, rising: phase == .inhale)
                if phase == .inhale {
                    SoundEffectPlayer.shared.play(.chime, volume: 0.3)
                }
            }
        }
        .onDisappear { viewModel.stop() }
    }

    // MARK: - 子视图

    private var phaseLabel: some View {
        VStack(spacing: 8) {
            Text(viewModel.isRunning ? viewModel.phase.titleKey : "breathing.ready")
                .font(.largeTitle.bold())
                .foregroundStyle(.white)
                .contentTransition(.opacity)

            if viewModel.isRunning {
                Text("\(viewModel.secondsRemaining)")
                    .font(.system(size: 22, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))
                    .contentTransition(.numericText())
            }
        }
        .animation(.easeInOut, value: viewModel.phase)
    }

    private var breathingCircle: some View {
        ZStack {
            // 外层光晕
            Circle()
                .fill(.white.opacity(0.15))
                .frame(width: 280, height: 280)
                .scaleEffect(viewModel.circleScale)

            Circle()
                .fill(.white.opacity(0.25))
                .frame(width: 220, height: 220)
                .scaleEffect(viewModel.circleScale)

            // 核心圆
            Circle()
                .fill(
                    RadialGradient(colors: [.white, .white.opacity(0.6)],
                                   center: .center, startRadius: 10, endRadius: 90)
                )
                .frame(width: 160, height: 160)
                .scaleEffect(viewModel.circleScale)
                .shadow(color: .white.opacity(0.6), radius: 30)

            Image(systemName: "lungs.fill")
                .font(.system(size: 40))
                .foregroundStyle(accent)
                .scaleEffect(viewModel.circleScale)
        }
        .frame(height: 300)
    }

    private var cycleCounter: some View {
        Group {
            if viewModel.completedCycles > 0 {
                Label("breathing.cycles \(viewModel.completedCycles)", systemImage: "repeat")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.9))
            }
        }
    }

    private var controlButton: some View {
        Button {
            haptics.playSelection()
            if viewModel.isRunning {
                viewModel.stop()
            } else {
                viewModel.start()
            }
        } label: {
            Text(viewModel.isRunning ? "breathing.stop" : "breathing.start")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .foregroundStyle(accent)
                .background(.white, in: Capsule())
        }
        .padding(.horizontal, 40)
    }
}

#Preview {
    NavigationStack {
        BreathingView()
            .environment(HapticManager())
    }
}
