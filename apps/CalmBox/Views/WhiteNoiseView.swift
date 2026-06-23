//
//  WhiteNoiseView.swift
//  CalmBox
//
//  白噪音盒与混音器：多声源叠加，每个声源独立开关与音量；
//  支持保存/加载混音预设（SwiftData）。付费声源在未解锁时弹出付费墙。
//

import SwiftUI
import SwiftData

struct WhiteNoiseView: View {

    @Environment(AudioManager.self) private var audio
    @Environment(PurchaseManager.self) private var purchaseManager
    @Environment(HapticManager.self) private var haptics
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \MixerPreset.createdAt, order: .reverse) private var presets: [MixerPreset]

    @State private var showPaywall = false
    @State private var showSavePresetAlert = false
    @State private var newPresetName = ""

    private let accent = Theme.Scene.accent(.whiteNoise)

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                masterControl
                soundGrid
                if !presets.isEmpty {
                    presetsSection
                }
            }
            .padding()
        }
        .navigationTitle("scene.whitenoise.title")
        .navigationBarTitleDisplayMode(.inline)
        .sceneBackground(.whiteNoise, opacity: 0.12)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    haptics.playSelection()
                    showSavePresetAlert = true
                } label: {
                    Image(systemName: "plus.circle")
                }
                .disabled(!audio.isAnyPlaying)
                .accessibilityLabel("mixer.savePreset")
            }
        }
        .sheet(isPresented: $showPaywall) { PaywallView() }
        .alert("mixer.savePreset", isPresented: $showSavePresetAlert) {
            TextField("mixer.presetName", text: $newPresetName)
            Button("common.cancel", role: .cancel) { newPresetName = "" }
            Button("common.save") { savePreset() }
        } message: {
            Text("mixer.savePreset.message")
        }
    }

    // MARK: - 主控制

    private var masterControl: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "speaker.wave.2.fill")
                    .foregroundStyle(accent)
                Text("mixer.masterVolume")
                    .font(.subheadline.weight(.medium))
                Spacer()
                if audio.isAnyPlaying {
                    Button {
                        haptics.playSelection()
                        audio.stopAll()
                    } label: {
                        Label("mixer.stopAll", systemImage: "stop.fill")
                            .font(.caption.weight(.semibold))
                    }
                    .buttonStyle(.bordered)
                    .tint(accent)
                }
            }
            Slider(
                value: Binding(
                    get: { Double(audio.masterVolume) },
                    set: { audio.masterVolume = Float($0) }
                ),
                in: 0...1
            )
            .tint(accent)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
    }

    // MARK: - 声源网格

    private var soundGrid: some View {
        LazyVGrid(columns: columns, spacing: 14) {
            ForEach(SoundSource.catalog) { source in
                SoundTile(
                    source: source,
                    isPlaying: audio.isPlaying(source),
                    volume: audio.volume(for: source),
                    isLocked: source.isPremium && !purchaseManager.hasUnlockedAll,
                    onToggle: { toggle(source) },
                    onVolumeChange: { audio.setVolume($0, for: source) }
                )
            }
        }
    }

    // MARK: - 预设

    private var presetsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("mixer.presets", systemImage: "bookmark.fill")
                .font(.headline)
            ForEach(presets) { preset in
                HStack {
                    Button {
                        loadPreset(preset)
                    } label: {
                        HStack {
                            Image(systemName: "waveform.circle.fill")
                                .foregroundStyle(accent)
                            Text(preset.name)
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "play.circle")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
                .padding(12)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
                .swipeActions {
                    Button(role: .destructive) {
                        deletePreset(preset)
                    } label: {
                        Label("common.delete", systemImage: "trash")
                    }
                }
            }
        }
    }

    // MARK: - 动作

    private func toggle(_ source: SoundSource) {
        if source.isPremium && !purchaseManager.hasUnlockedAll {
            haptics.playSelection()
            showPaywall = true
            return
        }
        haptics.playSelection()
        audio.toggle(source)
    }

    private func savePreset() {
        let name = newPresetName.trimmingCharacters(in: .whitespaces)
        let finalName = name.isEmpty ? String(localized: "mixer.defaultPresetName") : name
        let preset = MixerPreset(name: finalName, mix: audio.currentMix())
        modelContext.insert(preset)
        try? modelContext.save()
        haptics.playSuccess()
        newPresetName = ""
    }

    private func loadPreset(_ preset: MixerPreset) {
        haptics.playSelection()
        // 过滤掉未解锁的付费声源。
        let available = SoundSource.catalog.filter { purchaseManager.isAvailable($0) }
        let filteredMix = preset.mix.filter { key, _ in available.contains { $0.id == key } }
        audio.applyMix(filteredMix, catalog: available)
    }

    private func deletePreset(_ preset: MixerPreset) {
        modelContext.delete(preset)
        try? modelContext.save()
    }
}

// MARK: - 单个声源磁贴

private struct SoundTile: View {
    let source: SoundSource
    let isPlaying: Bool
    let volume: Float
    let isLocked: Bool
    let onToggle: () -> Void
    let onVolumeChange: (Float) -> Void

    var body: some View {
        VStack(spacing: 12) {
            Button(action: onToggle) {
                ZStack(alignment: .topTrailing) {
                    VStack(spacing: 8) {
                        Image(systemName: source.systemImage)
                            .font(.system(size: 30))
                            .foregroundStyle(isPlaying ? .white : source.tint)
                            .symbolEffect(.variableColor.iterative, isActive: isPlaying)
                        Text(source.nameKey)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(isPlaying ? .white : .primary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)

                    if isLocked {
                        Image(systemName: "lock.fill")
                            .font(.caption2)
                            .foregroundStyle(isPlaying ? .white : .secondary)
                            .padding(6)
                    }
                }
                .background(
                    isPlaying
                        ? AnyShapeStyle(LinearGradient(colors: [source.tint, source.tint.opacity(0.7)],
                                                       startPoint: .topLeading, endPoint: .bottomTrailing))
                        : AnyShapeStyle(Color(.secondarySystemBackground)),
                    in: RoundedRectangle(cornerRadius: 18)
                )
            }
            .buttonStyle(.plain)

            // 仅在播放时显示音量条。
            if isPlaying {
                Slider(
                    value: Binding(
                        get: { Double(volume) },
                        set: { onVolumeChange(Float($0)) }
                    ),
                    in: 0...1
                )
                .tint(source.tint)
                .transition(.opacity.combined(with: .scale))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: isPlaying)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(source.displayName)
        .accessibilityValue(isPlaying ? Text("mixer.playing") : Text("mixer.stopped"))
    }
}

#Preview {
    NavigationStack {
        WhiteNoiseView()
            .environment(AudioManager())
            .environment(PurchaseManager())
            .environment(HapticManager())
            .modelContainer(for: [MixerPreset.self], inMemory: true)
    }
}
