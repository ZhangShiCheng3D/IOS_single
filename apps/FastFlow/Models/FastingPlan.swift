//
//  FastingPlan.swift
//  FastFlow
//
//  断食方案模型。内置 16:8 / 18:6 / 20:4，并支持用户自定义方案（高级功能）。
//

import Foundation
import SwiftData

@Model
final class FastingPlan {
    /// 方案唯一标识。
    @Attribute(.unique) var id: UUID
    /// 方案名称，如 "16:8"。
    var name: String
    /// 断食小时数。
    var fastingHours: Int
    /// 进食窗口小时数。
    var eatingHours: Int
    /// 是否为用户自定义方案（区别于内置方案）。
    var isCustom: Bool
    /// 创建时间，用于排序。
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        fastingHours: Int,
        eatingHours: Int,
        isCustom: Bool = false,
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.fastingHours = fastingHours
        self.eatingHours = eatingHours
        self.isCustom = isCustom
        self.createdAt = createdAt
    }

    /// 目标断食时长（秒），供计时器使用。
    var targetDuration: TimeInterval {
        TimeInterval(fastingHours) * 3600
    }

    /// 展示用副标题，例如 "16 小时断食 · 8 小时进食"。
    var subtitle: String {
        String(
            format: NSLocalizedString("plan.subtitle.format", comment: ""),
            fastingHours, eatingHours
        )
    }
}

// MARK: - 默认方案种子

extension FastingPlan {
    /// 内置方案定义：(名称, 断食小时, 进食小时)。
    static let builtInDefinitions: [(name: String, fasting: Int, eating: Int)] = [
        ("16:8", 16, 8),
        ("18:6", 18, 6),
        ("20:4", 20, 4),
        ("OMAD", 23, 1)
    ]

    /// 若数据库为空则写入内置方案，保证首启即有可选方案。
    static func seedDefaultPlansIfNeeded(in context: ModelContext) {
        let descriptor = FetchDescriptor<FastingPlan>()
        let existing = (try? context.fetchCount(descriptor)) ?? 0
        guard existing == 0 else { return }

        for def in builtInDefinitions {
            context.insert(
                FastingPlan(
                    name: def.name,
                    fastingHours: def.fasting,
                    eatingHours: def.eating,
                    isCustom: false
                )
            )
        }
        try? context.save()
    }
}
