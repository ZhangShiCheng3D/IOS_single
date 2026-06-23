//
//  CollageProject.swift
//  CollageKit
//
//  SwiftData 持久化模型：一个拼图工程及其照片、文字、用户预设。
//

import Foundation
import SwiftData
import CoreGraphics

/// 一个拼图工程。
@Model
final class CollageProject {
    @Attribute(.unique) var id: UUID
    var title: String
    var createdAt: Date
    var updatedAt: Date

    /// 模板 ID（对应 TemplateLibrary）。
    var templateID: String
    /// 画布比例原始值。
    var aspectRatioRaw: String

    // 外观参数
    var borderWidth: Double      // 外边框宽度（点）
    var spacing: Double          // 插槽间距（点）
    var cornerRadius: Double     // 圆角半径（点）

    // 背景
    var backgroundKindRaw: String
    var backgroundColorHex: String
    var gradientStartHex: String
    var gradientEndHex: String
    var gradientAngle: Double    // 角度（度）

    @Relationship(deleteRule: .cascade, inverse: \CollagePhoto.project)
    var photos: [CollagePhoto] = []

    @Relationship(deleteRule: .cascade, inverse: \CollageText.project)
    var texts: [CollageText] = []

    init(title: String = "",
         template: CollageTemplate = TemplateLibrary.default) {
        self.id = UUID()
        self.title = title
        self.createdAt = .now
        self.updatedAt = .now
        self.templateID = template.id
        self.aspectRatioRaw = template.preferredRatio.rawValue
        self.borderWidth = 0
        self.spacing = 8
        self.cornerRadius = 12
        self.backgroundKindRaw = BackgroundKind.solid.rawValue
        self.backgroundColorHex = "#FFFFFF"
        self.gradientStartHex = "#FDE4CF"
        self.gradientEndHex = "#C8B6FF"
        self.gradientAngle = 45
    }

    // MARK: - 计算属性

    var template: CollageTemplate {
        TemplateLibrary.template(withID: templateID) ?? TemplateLibrary.default
    }

    var aspectRatio: AspectRatio {
        get { AspectRatio(rawValue: aspectRatioRaw) ?? .square }
        set { aspectRatioRaw = newValue.rawValue }
    }

    var backgroundKind: BackgroundKind {
        get { BackgroundKind(rawValue: backgroundKindRaw) ?? .solid }
        set { backgroundKindRaw = newValue.rawValue }
    }

    /// 返回指定插槽序号的照片（若存在）。
    func photo(forSlot index: Int) -> CollagePhoto? {
        photos.first { $0.slotIndex == index }
    }

    func touch() {
        updatedAt = .now
    }
}

/// 工程内的一张照片，绑定到某个插槽。
@Model
final class CollagePhoto {
    @Attribute(.unique) var id: UUID
    /// 对应模板插槽序号。
    var slotIndex: Int
    /// 已降采样的图片数据（JPEG）。
    @Attribute(.externalStorage) var imageData: Data
    /// 在插槽内的缩放（1 = 填充）。
    var scale: Double
    /// 在插槽内的归一化偏移（-0.5 ~ 0.5）。
    var offsetX: Double
    var offsetY: Double

    var project: CollageProject?

    init(slotIndex: Int, imageData: Data) {
        self.id = UUID()
        self.slotIndex = slotIndex
        self.imageData = imageData
        self.scale = 1.0
        self.offsetX = 0
        self.offsetY = 0
    }
}

/// 文字叠加层。
@Model
final class CollageText {
    @Attribute(.unique) var id: UUID
    var content: String
    /// 归一化位置（0~1，相对画布）。
    var normX: Double
    var normY: Double
    var fontSize: Double          // 相对画布高度的比例 * 1000，便于缩放
    var colorHex: String
    var weightRaw: String
    var rotation: Double          // 角度

    var project: CollageProject?

    init(content: String,
         normX: Double = 0.5,
         normY: Double = 0.5) {
        self.id = UUID()
        self.content = content
        self.normX = normX
        self.normY = normY
        self.fontSize = 60
        self.colorHex = "#222222"
        self.weightRaw = TextWeight.bold.rawValue
        self.rotation = 0
    }

    var weight: TextWeight {
        get { TextWeight(rawValue: weightRaw) ?? .bold }
        set { weightRaw = newValue.rawValue }
    }
}

/// 用户保存的预设（模板 + 外观参数组合）。
@Model
final class UserPreset {
    @Attribute(.unique) var id: UUID
    var name: String
    var createdAt: Date

    var templateID: String
    var aspectRatioRaw: String
    var borderWidth: Double
    var spacing: Double
    var cornerRadius: Double
    var backgroundKindRaw: String
    var backgroundColorHex: String
    var gradientStartHex: String
    var gradientEndHex: String
    var gradientAngle: Double

    init(name: String, project: CollageProject) {
        self.id = UUID()
        self.name = name
        self.createdAt = .now
        self.templateID = project.templateID
        self.aspectRatioRaw = project.aspectRatioRaw
        self.borderWidth = project.borderWidth
        self.spacing = project.spacing
        self.cornerRadius = project.cornerRadius
        self.backgroundKindRaw = project.backgroundKindRaw
        self.backgroundColorHex = project.backgroundColorHex
        self.gradientStartHex = project.gradientStartHex
        self.gradientEndHex = project.gradientEndHex
        self.gradientAngle = project.gradientAngle
    }

    /// 把预设应用到工程。
    func apply(to project: CollageProject) {
        project.templateID = templateID
        project.aspectRatioRaw = aspectRatioRaw
        project.borderWidth = borderWidth
        project.spacing = spacing
        project.cornerRadius = cornerRadius
        project.backgroundKindRaw = backgroundKindRaw
        project.backgroundColorHex = backgroundColorHex
        project.gradientStartHex = gradientStartHex
        project.gradientEndHex = gradientEndHex
        project.gradientAngle = gradientAngle
        project.touch()
    }
}
