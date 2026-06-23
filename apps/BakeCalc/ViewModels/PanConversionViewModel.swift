//
//  PanConversionViewModel.swift
//  BakeCalc
//
//  模具尺寸换算 ViewModel。按底面积比例换算配方用量：
//  目标用量 = 原用量 × (目标模具面积 / 源模具面积)。
//

import Foundation

final class PanConversionViewModel: ObservableObject {

    @Published var fromPan: PanSize = BakingData.panSizes.first { $0.shape == .round } ?? BakingData.panSizes[0]
    @Published var toPan: PanSize = BakingData.panSizes.first { $0.shape == .round && $0.dimensionA == 23 } ?? BakingData.panSizes[1]

    /// 面积比例（目标 / 源）。
    var areaRatio: Double {
        guard fromPan.area > 0 else { return .nan }
        return toPan.area / fromPan.area
    }

    var ratioText: String {
        guard areaRatio.isFinite else { return "—" }
        return "×" + NumberFormatting.formatted(areaRatio, maxFraction: 2)
    }

    var fromAreaText: String { NumberFormatting.formatted(fromPan.area, maxFraction: 0) }
    var toAreaText: String { NumberFormatting.formatted(toPan.area, maxFraction: 0) }

    /// 将某一原料用量按面积比例换算。
    func scaled(_ amount: Double) -> Double {
        amount * areaRatio
    }

    func swap() {
        (fromPan, toPan) = (toPan, fromPan)
    }
}
