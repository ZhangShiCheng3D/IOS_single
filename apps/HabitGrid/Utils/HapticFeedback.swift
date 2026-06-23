//
//  HapticFeedback.swift
//  HabitGrid
//
//  轻量触感反馈封装，让“点格子打卡”有满足感。
//

import SwiftUI

#if canImport(UIKit)
import UIKit

enum Haptics {
    /// 打卡成功的轻快反馈。
    static func tap() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    /// 达成里程碑（如连续天数破纪录）的成功反馈。
    static func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    /// 选择/切换的轻微反馈。
    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}
#else
enum Haptics {
    static func tap() {}
    static func success() {}
    static func selection() {}
}
#endif
