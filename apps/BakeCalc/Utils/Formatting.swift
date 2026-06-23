//
//  Formatting.swift
//  BakeCalc
//
//  数值格式化与解析工具。烘焙换算结果需要既精确又易读，
//  这里统一处理小数位、千分位以及本地化输入解析。
//

import Foundation

enum NumberFormatting {

    /// 烘焙结果格式化：智能小数位。
    /// - 大于等于 100 取整或保留 1 位；小于 10 保留 2 位；否则 1 位。
    static func smart(_ value: Double) -> String {
        guard value.isFinite else { return "—" }
        let absValue = abs(value)
        let fractionDigits: Int
        switch absValue {
        case 0:                 fractionDigits = 0
        case ..<1:              fractionDigits = 2
        case ..<10:             fractionDigits = 2
        case ..<100:            fractionDigits = 1
        default:                fractionDigits = 0
        }
        return formatted(value, maxFraction: fractionDigits)
    }

    /// 按指定最大小数位格式化，去除多余的尾随零，并加千分位。
    static func formatted(_ value: Double, maxFraction: Int) -> String {
        guard value.isFinite else { return "—" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = maxFraction
        formatter.roundingMode = .halfUp
        return formatter.string(from: NSNumber(value: value)) ?? String(value)
    }

    /// 解析用户输入文本为 Double，兼容中文逗号、空格与本地化小数点。
    static func parse(_ text: String) -> Double? {
        let cleaned = text
            .trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: "，", with: "")
        guard !cleaned.isEmpty else { return nil }
        return Double(cleaned)
    }
}

extension Double {
    /// 便捷的智能格式化属性。
    var bcSmart: String { NumberFormatting.smart(self) }
}
