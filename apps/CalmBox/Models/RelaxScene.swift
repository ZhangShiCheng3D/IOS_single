//
//  RelaxScene.swift
//  CalmBox
//
//  解压场景（功能模块）的静态定义，用于主页网格展示与导航。
//

import Foundation
import SwiftUI

/// 解压场景的功能类型，用于导航分发。
enum SceneKind: String, Codable, CaseIterable {
    case bubbleWrap     // 泡泡纸
    case spinner        // 陀螺
    case whiteNoise     // 白噪音混音器
    case breathing      // 呼吸引导
    case meditation     // 冥想计时器
}

/// 主页展示的一个解压场景卡片。
struct RelaxScene: Identifiable, Hashable {
    let id: String
    let kind: SceneKind
    let titleKey: LocalizedStringKey
    let displayTitle: String
    let subtitleKey: LocalizedStringKey
    let displaySubtitle: String
    let systemImage: String
    /// 是否为付费场景。
    let isPremium: Bool

    /// 渐变色，用于卡片背景（统一取自 Theme，按场景类型派生）。
    var gradient: [Color] { Theme.Scene.gradient(kind) }
    /// 场景主色，用于强调元素。
    var accent: Color { Theme.Scene.accent(kind) }

    // LocalizedStringKey 不遵守 Hashable，无法自动合成；按稳定的 id 实现。
    static func == (lhs: RelaxScene, rhs: RelaxScene) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

extension RelaxScene {

    /// 全部解压场景目录。
    static let catalog: [RelaxScene] = [
        RelaxScene(
            id: "bubble", kind: .bubbleWrap,
            titleKey: "scene.bubble.title", displayTitle: "泡泡纸",
            subtitleKey: "scene.bubble.subtitle", displaySubtitle: "捏破解压，啵啵作响",
            systemImage: "circle.grid.3x3.fill",
            isPremium: false
        ),
        RelaxScene(
            id: "spinner", kind: .spinner,
            titleKey: "scene.spinner.title", displayTitle: "解压陀螺",
            subtitleKey: "scene.spinner.subtitle", displaySubtitle: "拨动旋转，物理手感",
            systemImage: "fan.fill",
            isPremium: false
        ),
        RelaxScene(
            id: "whitenoise", kind: .whiteNoise,
            titleKey: "scene.whitenoise.title", displayTitle: "白噪音盒",
            subtitleKey: "scene.whitenoise.subtitle", displaySubtitle: "多声源叠加混音",
            systemImage: "waveform",
            isPremium: false
        ),
        RelaxScene(
            id: "breathing", kind: .breathing,
            titleKey: "scene.breathing.title", displayTitle: "呼吸引导",
            subtitleKey: "scene.breathing.subtitle", displaySubtitle: "4-7-8 助眠呼吸法",
            systemImage: "lungs.fill",
            isPremium: true
        ),
        RelaxScene(
            id: "meditation", kind: .meditation,
            titleKey: "scene.meditation.title", displayTitle: "冥想计时",
            subtitleKey: "scene.meditation.subtitle", displaySubtitle: "静心，伴音入眠",
            systemImage: "moon.zzz.fill",
            isPremium: true
        )
    ]

    static func scene(for id: String) -> RelaxScene? {
        catalog.first { $0.id == id }
    }
}
