//
//  TemperatureConverter.swift
//  BakeCalc
//
//  温度换算工具：摄氏 ↔ 华氏。另含烤箱档位匹配。
//

import Foundation

enum TemperatureConverter {

    /// 摄氏 → 华氏。
    static func celsiusToFahrenheit(_ c: Double) -> Double {
        c * 9.0 / 5.0 + 32.0
    }

    /// 华氏 → 摄氏。
    static func fahrenheitToCelsius(_ f: Double) -> Double {
        (f - 32.0) * 5.0 / 9.0
    }
}

/// 温标。
enum TemperatureScale: String, CaseIterable, Identifiable, Codable {
    case celsius
    case fahrenheit

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .celsius:    return "°C"
        case .fahrenheit: return "°F"
        }
    }

    var localizedKey: String {
        switch self {
        case .celsius:    return "temp.celsius"
        case .fahrenheit: return "temp.fahrenheit"
        }
    }
}
