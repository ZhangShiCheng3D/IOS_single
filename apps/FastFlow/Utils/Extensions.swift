//
//  Extensions.swift
//  FastFlow
//
//  通用扩展与格式化工具。
//

import Foundation
import SwiftUI
import UIKit

// MARK: - TimeInterval 格式化

extension TimeInterval {
    /// 格式化为 "HH:mm:ss"（断食计时主显示）。
    var asClockString: String {
        let total = Int(max(0, self))
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }

    /// 格式化为简短可读形式，如 "16 小时 12 分"。
    var asReadableDuration: String {
        let total = Int(max(0, self))
        let h = total / 3600
        let m = (total % 3600) / 60
        if h > 0 {
            return String(format: NSLocalizedString("duration.hm.format", comment: ""), h, m)
        }
        return String(format: NSLocalizedString("duration.m.format", comment: ""), m)
    }
}

// MARK: - Date 工具

extension Date {
    /// 当天起始（本地时区 00:00）。
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    /// 是否与另一日期同一天。
    func isSameDay(as other: Date) -> Bool {
        Calendar.current.isDate(self, inSameDayAs: other)
    }

    /// 距今偏移天数的当天起始（负数为过去）。
    func dayOffset(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: startOfDay) ?? self
    }
}

// MARK: - 颜色快捷方式

extension Color {
    /// 主品牌色（来自 Asset，回退到代码值以防资源缺失）。
    static let brand = Color("AccentColor")
    /// 喝水主题色。
    static let water = Color(red: 0.20, green: 0.62, blue: 0.92)
    /// 断食达成色。
    static let goalReached = Color(red: 0.30, green: 0.78, blue: 0.55)
}

// MARK: - 触感反馈

enum Haptics {
    /// 轻量成功反馈。
    static func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    /// 轻触反馈。
    static func tap() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
}
