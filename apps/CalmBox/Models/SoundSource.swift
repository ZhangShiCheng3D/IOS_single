//
//  SoundSource.swift
//  CalmBox
//
//  白噪音声源的静态定义。声源音频文件应放置在 App Bundle 的
//  Sounds/ 目录下（如 rain.m4a）。免费/付费由 isPremium 控制。
//

import Foundation
import SwiftUI

/// 单个白噪音声源。
struct SoundSource: Identifiable, Hashable {
    let id: String
    /// 本地化键，用于显示名称。
    let nameKey: LocalizedStringKey
    /// 用于展示的中文回退名（无本地化时使用）。
    let displayName: String
    /// SF Symbol 图标名。
    let systemImage: String
    /// 主题色。
    let tint: Color
    /// Bundle 中的音频文件名（不含扩展名）。
    let fileName: String
    /// 音频扩展名。
    let fileExtension: String
    /// 是否为付费内容。
    let isPremium: Bool

    /// 解析 Bundle 中的音频文件 URL。
    var fileURL: URL? {
        Bundle.main.url(forResource: fileName, withExtension: fileExtension, subdirectory: "Sounds")
            ?? Bundle.main.url(forResource: fileName, withExtension: fileExtension)
    }
}

extension SoundSource {

    /// 全部白噪音声源目录。
    static let catalog: [SoundSource] = [
        // 免费声源
        SoundSource(id: "rain", nameKey: "sound.rain", displayName: "雨声",
                    systemImage: "cloud.rain.fill", tint: .blue,
                    fileName: "rain", fileExtension: "m4a", isPremium: false),
        SoundSource(id: "fire", nameKey: "sound.fire", displayName: "炉火",
                    systemImage: "flame.fill", tint: .orange,
                    fileName: "fire", fileExtension: "m4a", isPremium: false),

        // 付费声源
        SoundSource(id: "waves", nameKey: "sound.waves", displayName: "海浪",
                    systemImage: "water.waves", tint: .teal,
                    fileName: "waves", fileExtension: "m4a", isPremium: true),
        SoundSource(id: "forest", nameKey: "sound.forest", displayName: "森林",
                    systemImage: "tree.fill", tint: .green,
                    fileName: "forest", fileExtension: "m4a", isPremium: true),
        SoundSource(id: "thunder", nameKey: "sound.thunder", displayName: "雷雨",
                    systemImage: "cloud.bolt.rain.fill", tint: .indigo,
                    fileName: "thunder", fileExtension: "m4a", isPremium: true),
        SoundSource(id: "wind", nameKey: "sound.wind", displayName: "风声",
                    systemImage: "wind", tint: .mint,
                    fileName: "wind", fileExtension: "m4a", isPremium: true),
        SoundSource(id: "stream", nameKey: "sound.stream", displayName: "溪流",
                    systemImage: "drop.fill", tint: .cyan,
                    fileName: "stream", fileExtension: "m4a", isPremium: true),
        SoundSource(id: "night", nameKey: "sound.night", displayName: "夏夜虫鸣",
                    systemImage: "moon.stars.fill", tint: .purple,
                    fileName: "night", fileExtension: "m4a", isPremium: true)
    ]

    static var freeSources: [SoundSource] { catalog.filter { !$0.isPremium } }
}
