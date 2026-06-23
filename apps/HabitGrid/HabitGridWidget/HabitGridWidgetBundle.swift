//
//  HabitGridWidgetBundle.swift
//  HabitGridWidget
//
//  Widget Extension 入口。注意：此文件属于独立的 Widget Target，
//  在 Xcode 中需为该 Target 加入 App Group 能力并共享所需源文件
//  （WidgetDataBridge.swift、Color+Hex.swift、Theme.swift、HabitStatistics.swift 等）。
//

import WidgetKit
import SwiftUI

@main
struct HabitGridWidgetBundle: WidgetBundle {
    var body: some Widget {
        HabitGridWidget()
    }
}
