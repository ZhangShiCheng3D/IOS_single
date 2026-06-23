//
//  AudioManager.swift
//  CalmBox
//
//  基于 AVFoundation 的白噪音引擎，支持多声源叠加混音、
//  独立音量控制、循环播放与后台播放。
//

import Foundation
import AVFoundation
import Observation

@Observable
final class AudioManager {

    /// 单个声源的播放状态。
    struct Channel: Identifiable {
        let id: String          // 对应 SoundSource.id
        var volume: Float       // 0...1
        var isPlaying: Bool
    }

    /// 当前所有活跃声道，键为声源 id。
    private(set) var channels: [String: Channel] = [:]

    /// 全局主音量。
    var masterVolume: Float = 1.0 {
        didSet { applyMasterVolume() }
    }

    /// 是否有任意声道正在播放。
    var isAnyPlaying: Bool {
        channels.values.contains { $0.isPlaying }
    }

    private var players: [String: AVAudioPlayer] = [:]
    private var sessionConfigured = false

    // MARK: - 音频会话

    /// 配置后台播放音频会话。首次播放前调用。
    func configureSessionIfNeeded() {
        guard !sessionConfigured else { return }
        do {
            let session = AVAudioSession.sharedInstance()
            // .playback 类别允许静音键开启时仍发声，并支持后台播放。
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
            sessionConfigured = true
        } catch {
            // 会话配置失败时仍尝试播放（前台可正常出声）。
        }
    }

    // MARK: - 播放控制

    /// 切换某个声源的播放状态。
    func toggle(_ source: SoundSource) {
        if let channel = channels[source.id], channel.isPlaying {
            stop(source)
        } else {
            play(source)
        }
    }

    /// 开始播放某个声源（若已存在则恢复）。
    func play(_ source: SoundSource, volume: Float = 0.7) {
        configureSessionIfNeeded()

        if let player = players[source.id] {
            player.volume = volume * masterVolume
            player.play()
            channels[source.id] = Channel(id: source.id, volume: volume, isPlaying: true)
            return
        }

        guard let url = source.fileURL else {
            // 资源缺失时不崩溃，仅记录为未播放。
            return
        }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1          // 无限循环
            player.volume = volume * masterVolume
            player.prepareToPlay()
            player.play()
            players[source.id] = player
            channels[source.id] = Channel(id: source.id, volume: volume, isPlaying: true)
        } catch {
            // 解码失败时跳过该声源。
        }
    }

    /// 停止某个声源并释放其播放器。
    func stop(_ source: SoundSource) {
        players[source.id]?.stop()
        players[source.id] = nil
        channels[source.id]?.isPlaying = false
        channels.removeValue(forKey: source.id)
    }

    /// 停止所有声源。
    func stopAll() {
        players.values.forEach { $0.stop() }
        players.removeAll()
        channels.removeAll()
    }

    /// 设置某个声源的音量。
    func setVolume(_ volume: Float, for source: SoundSource) {
        let clamped = max(0.0, min(1.0, volume))
        channels[source.id]?.volume = clamped
        players[source.id]?.volume = clamped * masterVolume
    }

    /// 获取某个声源的当前音量（未播放时返回默认 0.7）。
    func volume(for source: SoundSource) -> Float {
        channels[source.id]?.volume ?? 0.7
    }

    /// 某个声源是否正在播放。
    func isPlaying(_ source: SoundSource) -> Bool {
        channels[source.id]?.isPlaying ?? false
    }

    // MARK: - 混音预设

    /// 应用一组混音配置（来自保存的预设）。
    func applyMix(_ mix: [String: Float], catalog: [SoundSource]) {
        stopAll()
        for source in catalog {
            if let vol = mix[source.id], vol > 0 {
                play(source, volume: vol)
            }
        }
    }

    /// 导出当前混音为字典，便于持久化。
    func currentMix() -> [String: Float] {
        channels.values.reduce(into: [:]) { result, channel in
            if channel.isPlaying { result[channel.id] = channel.volume }
        }
    }

    // MARK: - 私有

    private func applyMasterVolume() {
        for (id, channel) in channels {
            players[id]?.volume = channel.volume * masterVolume
        }
    }
}
