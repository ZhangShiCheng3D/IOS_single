//
//  Medication.swift
//  SeniorHelper
//
//  用药计划数据模型（SwiftData @Model）。
//

import Foundation
import SwiftData

/// 一条用药计划。
///
/// 每条计划包含药品名称、剂量说明、每日提醒时间点、可选的药盒照片，
/// 以及是否启用提醒。照片以文件名形式存储，实际图片保存在沙盒 Documents 目录，
/// 避免将大体积二进制数据直接放入数据库。
@Model
final class Medication {

    /// 唯一标识，用于关联本地通知请求。
    var id: UUID

    /// 药品名称，例如「降压药」。
    var name: String

    /// 剂量与服用说明，例如「每次 1 片，饭后服用」。
    var dosage: String

    /// 每日提醒的时间点（仅取时分），可设置多个。
    var reminderTimes: [Date]

    /// 药盒照片在 Documents 目录中的文件名（含扩展名）。为空表示无照片。
    var photoFileName: String?

    /// 是否启用提醒。关闭后会撤销所有已排程的通知。
    var isEnabled: Bool

    /// 创建时间，用于列表排序。
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        dosage: String = "",
        reminderTimes: [Date] = [],
        photoFileName: String? = nil,
        isEnabled: Bool = true,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.dosage = dosage
        self.reminderTimes = reminderTimes
        self.photoFileName = photoFileName
        self.isEnabled = isEnabled
        self.createdAt = createdAt
    }
}

extension Medication {

    /// 将提醒时间格式化为「08:00、20:00」这样的可读字符串。
    var reminderTimesDescription: String {
        guard !reminderTimes.isEmpty else {
            return String(localized: "未设置提醒")
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return reminderTimes
            .sorted()
            .map { formatter.string(from: $0) }
            .joined(separator: "、")
    }

    /// 朗读用的完整描述。
    var spokenDescription: String {
        var parts = [name]
        if !dosage.isEmpty { parts.append(dosage) }
        if !reminderTimes.isEmpty {
            parts.append(String(localized: "提醒时间") + reminderTimesDescription)
        }
        return parts.joined(separator: "，")
    }
}
