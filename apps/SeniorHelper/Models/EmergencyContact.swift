//
//  EmergencyContact.swift
//  SeniorHelper
//
//  紧急联系人数据模型（SwiftData @Model）。
//

import Foundation
import SwiftData

/// 一位紧急联系人，用于首页一键拨号。
@Model
final class EmergencyContact {

    var id: UUID

    /// 联系人称呼，例如「女儿」「儿子」「社区医生」。
    var name: String

    /// 电话号码（仅保留数字与必要符号）。
    var phoneNumber: String

    /// 关系备注，可选，例如「家人」。
    var relationship: String

    /// 排序序号，数值越小越靠前。
    var sortOrder: Int

    init(
        id: UUID = UUID(),
        name: String,
        phoneNumber: String,
        relationship: String = "",
        sortOrder: Int = 0
    ) {
        self.id = id
        self.name = name
        self.phoneNumber = phoneNumber
        self.relationship = relationship
        self.sortOrder = sortOrder
    }
}

extension EmergencyContact {

    /// 生成可用于拨号的 `tel://` URL。号码非法时返回 nil。
    var dialURL: URL? {
        let sanitized = phoneNumber.filter { $0.isNumber || $0 == "+" || $0 == "*" || $0 == "#" }
        guard !sanitized.isEmpty else { return nil }
        return URL(string: "tel://\(sanitized)")
    }
}
