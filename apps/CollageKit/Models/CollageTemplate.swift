//
//  CollageTemplate.swift
//  CollageKit
//
//  模板定义。模板由若干「插槽」组成，每个插槽是单位坐标系（0~1）下的矩形，
//  渲染时根据画布实际尺寸换算为像素坐标。
//

import SwiftUI

/// 单个照片插槽，矩形使用单位坐标（0~1），原点在左上角。
struct TemplateSlot: Identifiable, Hashable {
    let id: Int
    /// 单位矩形：x, y, width, height 均为 0~1。
    let rect: CGRect

    init(_ id: Int, _ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) {
        self.id = id
        self.rect = CGRect(x: x, y: y, width: w, height: h)
    }
}

/// 拼图模板。
struct CollageTemplate: Identifiable, Hashable {
    let id: String
    let name: LocalizedStringKey
    let category: TemplateCategory
    /// 是否为付费模板（需要解锁 Pro）。
    let isPremium: Bool
    /// 推荐画布比例。
    let preferredRatio: AspectRatio
    /// 照片插槽集合。
    let slots: [TemplateSlot]

    var slotCount: Int { slots.count }

    static func == (lhs: CollageTemplate, rhs: CollageTemplate) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
