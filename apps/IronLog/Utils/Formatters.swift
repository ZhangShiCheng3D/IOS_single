//
//  Formatters.swift
//  IronLog
//
//  统一的数值/日期格式化，避免各处重复实现。
//

import Foundation

enum Fmt {

    /// 重量：去掉无意义的小数尾零（100.0 → "100"，2.5 → "2.5"）。
    static func weight(_ value: Double) -> String {
        if value == value.rounded() {
            return String(format: "%.0f", value)
        }
        return String(format: "%.1f", value)
    }

    /// 重量 + 单位（"100 kg"）。
    static func weight(_ value: Double, unit: WeightUnit) -> String {
        "\(weight(unit.display(fromKg: value))) \(unit.symbol)"
    }

    /// 容量/大数（带千分位）。
    static func volume(_ value: Double, unit: WeightUnit) -> String {
        let converted = unit.display(fromKg: value)
        let nf = NumberFormatter()
        nf.numberStyle = .decimal
        nf.maximumFractionDigits = 0
        let number = nf.string(from: NSNumber(value: converted)) ?? "\(Int(converted))"
        return "\(number) \(unit.symbol)"
    }

    /// 时长（mm:ss 或 h:mm:ss）。
    static func duration(_ seconds: TimeInterval) -> String {
        let total = Int(seconds.rounded())
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        }
        return String(format: "%d:%02d", m, s)
    }

    /// 计时器倒计时（mm:ss）。
    static func timer(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(seconds.rounded()))
        return String(format: "%d:%02d", total / 60, total % 60)
    }

    private static let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .none
        return df
    }()

    private static let dateTimeFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .short
        return df
    }()

    static func date(_ date: Date) -> String { dateFormatter.string(from: date) }
    static func dateTime(_ date: Date) -> String { dateTimeFormatter.string(from: date) }

    /// 相对友好日期（今天 / 昨天 / 具体日期）。
    static func relativeDay(_ date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) { return String(localized: "date.today") }
        if cal.isDateInYesterday(date) { return String(localized: "date.yesterday") }
        return self.date(date)
    }
}
