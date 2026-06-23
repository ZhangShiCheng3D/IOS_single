//
//  WorkoutSession.swift
//  IronLog
//
//  训练日记录：一次完整的训练（包含若干动作的若干组）。
//

import Foundation
import SwiftData

/// 一次训练会话。
@Model
final class WorkoutSession {
    @Attribute(.unique) var id: UUID
    /// 训练名称（可选，如「推日」「腿日」）。
    var name: String
    /// 开始时间。
    var date: Date
    /// 结束时间（用于计算时长）。完成后写入。
    var endDate: Date?
    /// 备注。
    var notes: String
    /// 该次训练来源的模板名（如有）。
    var templateName: String?

    /// 该次训练的所有组记录。删除训练时级联删除组。
    @Relationship(deleteRule: .cascade, inverse: \SetEntry.session)
    var sets: [SetEntry] = []

    init(
        id: UUID = UUID(),
        name: String = "",
        date: Date = .now,
        endDate: Date? = nil,
        notes: String = "",
        templateName: String? = nil
    ) {
        self.id = id
        self.name = name
        self.date = date
        self.endDate = endDate
        self.notes = notes
        self.templateName = templateName
    }

    // MARK: - 计算属性

    /// 是否仍在进行（尚未结束）。
    var isActive: Bool { endDate == nil }

    /// 训练时长（秒）。进行中则到现在为止。
    var duration: TimeInterval {
        (endDate ?? .now).timeIntervalSince(date)
    }

    /// 已完成组数。
    var completedSetCount: Int {
        sets.filter { $0.isCompleted }.count
    }

    /// 该次训练的总容量（Tonnage）= Σ(重量 × 次数)，仅计已完成的正式组。
    var totalVolume: Double {
        sets
            .filter { $0.isCompleted && !$0.isWarmup }
            .reduce(0) { $0 + $1.volume }
    }

    /// 涉及的动作（去重，按首次出现顺序）。
    var exercises: [Exercise] {
        var seen = Set<String>()
        var result: [Exercise] = []
        for set in sets.sorted(by: { $0.order < $1.order }) {
            guard let ex = set.exercise else { continue }
            if seen.insert(ex.id).inserted {
                result.append(ex)
            }
        }
        return result
    }

    /// 按动作分组的组记录，保持动作首次出现顺序。
    func setsGrouped() -> [(exercise: Exercise, sets: [SetEntry])] {
        var order: [String] = []
        var buckets: [String: [SetEntry]] = [:]
        for set in sets.sorted(by: { $0.order < $1.order }) {
            guard let ex = set.exercise else { continue }
            if buckets[ex.id] == nil { order.append(ex.id) }
            buckets[ex.id, default: []].append(set)
        }
        return order.compactMap { id in
            guard let ex = buckets[id]?.first?.exercise else { return nil }
            return (ex, buckets[id] ?? [])
        }
    }
}
