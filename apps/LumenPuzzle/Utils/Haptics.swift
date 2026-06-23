//
//  Haptics.swift
//  LumenPuzzle
//
//  轻量触觉反馈封装。集中管理，避免在各处重复创建 generator。
//

import UIKit

/// 触觉反馈帮助类。所有方法在主线程调用即可。
///
/// 标注 `@MainActor`：UIKit 的 `UIFeedbackGenerator` 系列在 Swift 6 严格并发下
/// 为主 actor 隔离，若本类型为非隔离上下文则无法在同步方法中构造它们。
/// 全部调用点（ViewModel、View body、手势协调器）本就运行在主 actor，标注无副作用。
@MainActor
enum Haptics {

    /// 目标被点亮时的轻微"叮"。
    static func tick() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    /// 关卡完成时的成功反馈。
    static func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    /// 选择/点击的柔和反馈。
    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}
