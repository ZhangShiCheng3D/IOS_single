//
//  TemperatureViewModel.swift
//  BakeCalc
//
//  温度换算 ViewModel：摄氏 ↔ 华氏，并匹配最接近的烤箱档位。
//

import Foundation

final class TemperatureViewModel: ObservableObject {

    @Published var inputText: String = "180"
    @Published var inputScale: TemperatureScale = .celsius

    /// 输出温标（与输入相反）。
    var outputScale: TemperatureScale {
        inputScale == .celsius ? .fahrenheit : .celsius
    }

    var inputValue: Double? {
        NumberFormatting.parse(inputText)
    }

    /// 换算结果数值。
    var result: Double? {
        guard let value = inputValue else { return nil }
        switch inputScale {
        case .celsius:    return TemperatureConverter.celsiusToFahrenheit(value)
        case .fahrenheit: return TemperatureConverter.fahrenheitToCelsius(value)
        }
    }

    var resultText: String {
        guard let result else { return "—" }
        return NumberFormatting.formatted(result, maxFraction: 1)
    }

    /// 输入值对应的摄氏温度（用于匹配烤箱档位）。
    private var celsiusValue: Double? {
        guard let value = inputValue else { return nil }
        return inputScale == .celsius ? value : TemperatureConverter.fahrenheitToCelsius(value)
    }

    /// 最接近的烤箱档位参考。
    var closestOven: OvenReference? {
        guard let c = celsiusValue else { return nil }
        return BakingData.ovenReferences.min { lhs, rhs in
            abs(Double(lhs.celsius) - c) < abs(Double(rhs.celsius) - c)
        }
    }

    func toggleScale() {
        inputScale = inputScale == .celsius ? .fahrenheit : .celsius
    }
}
