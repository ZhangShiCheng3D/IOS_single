//
//  HabitAssets.swift
//  HabitGrid
//
//  习惯可选图标与颜色的预设集合。
//

import Foundation

enum HabitAssets {
    /// 可供用户选择的 SF Symbols 图标。覆盖运动、阅读、健康、效率等常见习惯。
    static let icons: [String] = [
        "checkmark.seal.fill",
        "figure.run",
        "figure.strengthtraining.traditional",
        "figure.yoga",
        "dumbbell.fill",
        "book.fill",
        "pencil.and.outline",
        "brain.head.profile",
        "drop.fill",
        "fork.knife",
        "leaf.fill",
        "bed.double.fill",
        "alarm.fill",
        "cup.and.saucer.fill",
        "heart.fill",
        "pills.fill",
        "moon.stars.fill",
        "sun.max.fill",
        "music.note",
        "paintbrush.fill",
        "camera.fill",
        "globe.asia.australia.fill",
        "dollarsign.circle.fill",
        "hands.sparkles.fill"
    ]

    /// 可供用户为习惯选择的强调色（hex）。
    static let colors: [String] = [
        "#39D353", // 绿
        "#3B82F6", // 蓝
        "#F97316", // 橙
        "#EC4899", // 粉
        "#8B5CF6", // 紫
        "#10B981", // 青绿
        "#EF4444", // 红
        "#EAB308", // 黄
        "#06B6D4", // 天蓝
        "#F43F5E", // 玫红
        "#84CC16", // 黄绿
        "#57606A"  // 灰
    ]
}
