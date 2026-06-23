//
//  Extensions.swift
//  IronLog
//
//  通用扩展与共享 UI 常量。
//

import SwiftUI

// 设计令牌（Color.ironAccent / Theme / cardStyle）已统一迁移至 DesignSystem.swift。

extension View {
    /// 条件修饰：仅当 condition 为真时应用 transform。
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition { transform(self) } else { self }
    }
}

extension Date {
    /// 当天起点。
    var startOfDay: Date { Calendar.current.startOfDay(for: self) }
}

extension Double {
    /// 四舍五入到最近的 step（用于杠铃片步进对齐）。
    func rounded(toNearest step: Double) -> Double {
        guard step > 0 else { return self }
        return (self / step).rounded() * step
    }
}
