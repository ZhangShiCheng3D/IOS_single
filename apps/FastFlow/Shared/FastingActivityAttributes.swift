//
//  FastingActivityAttributes.swift
//  FastFlow
//
//  Live Activity / Widget 与主 App 共享的活动属性定义。
//  ⚠️ 此文件需同时加入「主 App」与「Widget Extension」两个 Target。
//

import Foundation
import ActivityKit

/// 断食 Live Activity 的属性。
/// - `ContentState` 为可变状态，随计时更新推送到锁屏 / 灵动岛。
struct FastingActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        /// 断食开始时间。
        var startTime: Date
        /// 目标结束时间（开始 + 目标时长）。
        var targetEndTime: Date
        /// 方案名称，如 "16:8"。
        var planName: String
        /// 是否已达成目标（用于切换文案/配色）。
        var hasReachedGoal: Bool

        /// 计时区间，供 SwiftUI `Text(timerInterval:)` 自动走时。
        var timerRange: ClosedRange<Date> {
            // 保证区间合法（end >= start）。
            let end = max(targetEndTime, startTime.addingTimeInterval(1))
            return startTime...end
        }
    }

    /// 静态属性：本次活动的方案名称（创建后不变）。
    var planName: String
}
