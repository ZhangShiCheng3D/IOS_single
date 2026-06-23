//
//  SoundEffectPlayer.swift
//  CalmBox
//
//  短促音效播放器（泡泡破裂、陀螺旋转等）。使用播放器池支持
//  快速连续触发而不互相打断，与白噪音会话共存（mixWithOthers）。
//

import Foundation
import AVFoundation

@MainActor
final class SoundEffectPlayer {

    static let shared = SoundEffectPlayer()

    /// 可用的短音效。
    enum Effect: String, CaseIterable {
        case bubblePop = "pop"
        case spinTick = "spin_tick"
        case chime = "chime"      // 计时/呼吸完成提示音

        var fileExtension: String { "caf" }
    }

    /// 每种音效预备多个播放器，循环使用以支持重叠播放。
    private var pools: [Effect: [AVAudioPlayer]] = [:]
    private var indices: [Effect: Int] = [:]
    private let poolSize = 6
    private var isEnabled = true

    private init() {
        preload()
    }

    /// 预加载所有音效播放器。
    private func preload() {
        for effect in Effect.allCases {
            guard let url = url(for: effect) else { continue }
            var players: [AVAudioPlayer] = []
            for _ in 0..<poolSize {
                if let player = try? AVAudioPlayer(contentsOf: url) {
                    player.prepareToPlay()
                    players.append(player)
                }
            }
            if !players.isEmpty {
                pools[effect] = players
                indices[effect] = 0
            }
        }
    }

    private func url(for effect: Effect) -> URL? {
        Bundle.main.url(forResource: effect.rawValue, withExtension: effect.fileExtension, subdirectory: "Sounds")
            ?? Bundle.main.url(forResource: effect.rawValue, withExtension: effect.fileExtension)
    }

    /// 播放一个音效。
    /// - Parameters:
    ///   - effect: 音效类型。
    ///   - volume: 音量 0...1。
    ///   - rate: 播放速率（用于陀螺等音高变化），默认 1.0。
    func play(_ effect: Effect, volume: Float = 1.0, rate: Float = 1.0) {
        guard isEnabled, let players = pools[effect], !players.isEmpty else { return }
        let index = (indices[effect] ?? 0) % players.count
        indices[effect] = index + 1

        let player = players[index]
        player.volume = volume
        if rate != 1.0 {
            player.enableRate = true
            player.rate = rate
        }
        player.currentTime = 0
        player.play()
    }

    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
    }
}
