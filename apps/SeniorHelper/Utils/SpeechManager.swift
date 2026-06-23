//
//  SpeechManager.swift
//  SeniorHelper
//
//  语音播报管理器，封装 AVSpeechSynthesizer。
//  面向老年用户：默认中文、语速略慢、清晰发音。
//

import Foundation
import AVFoundation
import Observation

/// 全局语音播报器。通过环境对象注入，任意页面均可调用 `speak`。
@Observable
final class SpeechManager: NSObject {

    /// 是否正在朗读，可用于驱动 UI（如停止按钮）。
    private(set) var isSpeaking = false

    /// 用户是否开启「语音优先」总开关，持久化到 UserDefaults。
    var isVoiceEnabled: Bool {
        didSet { UserDefaults.standard.set(isVoiceEnabled, forKey: Self.voiceKey) }
    }

    private static let voiceKey = "settings.voiceEnabled"

    private let synthesizer = AVSpeechSynthesizer()

    override init() {
        // 默认开启语音（首次安装时键不存在，object(forKey:) 为 nil → 默认 true）。
        if UserDefaults.standard.object(forKey: Self.voiceKey) == nil {
            isVoiceEnabled = true
        } else {
            isVoiceEnabled = UserDefaults.standard.bool(forKey: Self.voiceKey)
        }
        super.init()
        synthesizer.delegate = self
    }

    /// 朗读一段文本。`force` 为 true 时忽略总开关（如点击「朗读」按钮）。
    func speak(_ text: String, force: Bool = false) {
        guard force || isVoiceEnabled else { return }
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        // 打断当前朗读，避免叠加。
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        configureAudioSession()

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "zh-CN")
        // 略低于默认语速，便于听清。
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.92
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        synthesizer.speak(utterance)
    }

    /// 立即停止朗读。
    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        isSpeaking = false
    }

    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            // 与其他音频混音播放，不打断用户正在听的内容。
            try session.setCategory(.playback, mode: .spokenAudio, options: [.mixWithOthers, .duckOthers])
            try session.setActive(true)
        } catch {
            print("配置音频会话失败: \(error.localizedDescription)")
        }
    }
}

extension SpeechManager: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        isSpeaking = true
    }
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        isSpeaking = false
    }
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        isSpeaking = false
    }
}
