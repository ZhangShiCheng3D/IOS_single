//
//  MeditationTimerView.swift
//  CalmBox
//
//  冥想计时器：选择时长，环形进度倒计时，可叠加白噪音，
//  完成后写入 SwiftData 会话记录。
//

import SwiftUI
import SwiftData

struct MeditationTimerView: View {

    @Environment(HapticManager.self) private var haptics
    @Environment(AudioManager.self) private var audio
    @Environment(\.modelContext) private var modelContext

    @State private var viewModel = MeditationViewModel()
    @State private var showAmbientPicker = false

    private let accent = Theme.Palette.brandStart

    var body: some View {
        ZStack {
            LinearGradient(
                colors: Theme.Palette.brandGradient,
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 36) {
                Spacer()

                if viewModel.isRunning {
                    timerRing
                } else {
                    durationPicker
                }

                Spacer()

                ambientToggle
                controls
            }
            .padding()
        }
        .navigationTitle("scene.meditation.title")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear {
            viewModel.onFinished = handleFinish
        }
        .onDisappear {
            if viewModel.isRunning {
                let session = viewModel.stop(completed: false)
                viewModel.persist(session, in: modelContext)
            }
        }
        .sheet(isPresented: $showAmbientPicker) {
            AmbientPickerSheet()
                .presentationDetents([.medium])
        }
    }

    // MARK: - 时长选择

    private var durationPicker: some View {
        VStack(spacing: 24) {
            Text("meditation.chooseDuration")
                .font(.title3.weight(.medium))
                .foregroundStyle(.white)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(MeditationViewModel.durationOptions, id: \.self) { minutes in
                    Button {
                        haptics.playSelection()
                        viewModel.selectedMinutes = minutes
                    } label: {
                        Text("\(minutes)")
                            .font(.title2.bold())
                            .frame(width: 80, height: 80)
                            .foregroundStyle(viewModel.selectedMinutes == minutes ? accent : .white)
                            .background(
                                viewModel.selectedMinutes == minutes ? Color.white : Color.white.opacity(0.15),
                                in: Circle()
                            )
                            .overlay(
                                Text("meditation.minuteUnit")
                                    .font(.caption2)
                                    .foregroundStyle(viewModel.selectedMinutes == minutes ? accent.opacity(0.7) : .white.opacity(0.7))
                                    .offset(y: 22)
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text("\(minutes) ") + Text("meditation.minuteUnit"))
                    .accessibilityAddTraits(viewModel.selectedMinutes == minutes ? .isSelected : [])
                }
            }
        }
    }

    // MARK: - 计时环

    private var timerRing: some View {
        ZStack {
            Circle()
                .stroke(.white.opacity(0.2), lineWidth: 14)

            Circle()
                .trim(from: 0, to: viewModel.progress)
                .stroke(
                    AngularGradient(colors: [.white.opacity(0.6), .white], center: .center),
                    style: StrokeStyle(lineWidth: 14, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: viewModel.progress)

            VStack(spacing: 6) {
                Text(viewModel.displayTime)
                    .font(.system(size: 52, weight: .light, design: .rounded))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
                    .monospacedDigit()
                if viewModel.isPaused {
                    Text("meditation.paused")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
        }
        .frame(width: 260, height: 260)
        .padding(.horizontal, 20)
    }

    // MARK: - 背景音

    private var ambientToggle: some View {
        Button {
            haptics.playSelection()
            showAmbientPicker = true
        } label: {
            HStack {
                Image(systemName: audio.isAnyPlaying ? "speaker.wave.2.fill" : "speaker.slash.fill")
                Text(audio.isAnyPlaying ? "meditation.ambientOn" : "meditation.ambientOff")
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
            }
            .font(.subheadline)
            .foregroundStyle(.white)
            .padding()
            .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
        }
        .padding(.horizontal, 40)
    }

    // MARK: - 控制按钮

    private var controls: some View {
        HStack(spacing: 16) {
            if viewModel.isRunning {
                Button {
                    haptics.playSelection()
                    viewModel.togglePause()
                } label: {
                    Image(systemName: viewModel.isPaused ? "play.fill" : "pause.fill")
                        .font(.title2)
                        .frame(width: 64, height: 64)
                        .foregroundStyle(accent)
                        .background(.white, in: Circle())
                }
                .accessibilityLabel(viewModel.isPaused ? "meditation.resume" : "meditation.pause")

                Button {
                    haptics.playSelection()
                    let session = viewModel.stop(completed: false)
                    viewModel.persist(session, in: modelContext)
                } label: {
                    Image(systemName: "stop.fill")
                        .font(.title2)
                        .frame(width: 64, height: 64)
                        .foregroundStyle(.white)
                        .background(.white.opacity(0.2), in: Circle())
                }
                .accessibilityLabel("meditation.stop")
            } else {
                Button {
                    haptics.playSelection()
                    viewModel.start()
                } label: {
                    Text("meditation.start")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .foregroundStyle(accent)
                        .background(.white, in: Capsule())
                }
            }
        }
        .padding(.horizontal, 40)
        .padding(.bottom, 20)
    }

    // MARK: - 完成处理

    private func handleFinish() {
        haptics.playSuccess()
        SoundEffectPlayer.shared.play(.chime, volume: 0.8)
        let session = viewModel.stop(completed: true)
        viewModel.persist(session, in: modelContext)
    }
}

// MARK: - 背景音选择弹窗

private struct AmbientPickerSheet: View {
    @Environment(AudioManager.self) private var audio
    @Environment(PurchaseManager.self) private var purchaseManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(SoundSource.catalog.filter { purchaseManager.isAvailable($0) }) { source in
                    Button {
                        audio.toggle(source)
                    } label: {
                        HStack {
                            Image(systemName: source.systemImage)
                                .foregroundStyle(source.tint)
                                .frame(width: 32)
                            Text(source.nameKey)
                                .foregroundStyle(.primary)
                            Spacer()
                            if audio.isPlaying(source) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(source.tint)
                            }
                        }
                    }
                }
            }
            .navigationTitle("meditation.selectAmbient")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("common.done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        MeditationTimerView()
            .environment(HapticManager())
            .environment(AudioManager())
            .environment(PurchaseManager())
            .modelContainer(for: [MeditationSession.self], inMemory: true)
    }
}
