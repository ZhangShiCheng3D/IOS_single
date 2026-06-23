//
//  FastingSession.swift
//  FastFlow
//
//  单次断食会话记录。一条记录代表一次从开始到结束（或进行中）的断食。
//

import Foundation
import SwiftData

@Model
final class FastingSession {
    /// 会话唯一标识。
    @Attribute(.unique) var id: UUID
    /// 断食开始时间。
    var startTime: Date
    /// 断食结束时间。nil 表示正在进行中。
    var endTime: Date?
    /// 该次会话的目标时长（秒），来自所选方案。
    var targetDuration: TimeInterval
    /// 所用方案名称快照（方案可能被删改，故存快照）。
    var planName: String
    /// 用户备注（可选）。
    var note: String?

    init(
        id: UUID = UUID(),
        startTime: Date = .now,
        endTime: Date? = nil,
        targetDuration: TimeInterval,
        planName: String,
        note: String? = nil
    ) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.targetDuration = targetDuration
        self.planName = planName
        self.note = note
    }

    /// 是否进行中。
    var isActive: Bool { endTime == nil }

    /// 实际已断食时长。进行中则计算到现在。
    var elapsed: TimeInterval {
        let end = endTime ?? .now
        return max(0, end.timeIntervalSince(startTime))
    }

    /// 实际完成时长（仅已结束会话有意义）。
    var completedDuration: TimeInterval {
        guard let endTime else { return elapsed }
        return max(0, endTime.timeIntervalSince(startTime))
    }

    /// 是否达成目标时长。
    var didReachGoal: Bool {
        completedDuration >= targetDuration
    }

    /// 完成进度 0...1（可超过 1，调用方按需 clamp）。
    var progress: Double {
        guard targetDuration > 0 else { return 0 }
        return elapsed / targetDuration
    }

    /// 计划结束时间（开始 + 目标时长）。
    var scheduledEndTime: Date {
        startTime.addingTimeInterval(targetDuration)
    }
}
