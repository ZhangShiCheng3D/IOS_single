//
//  CollageLayout.swift
//  CollageKit
//
//  插槽布局换算：把模板的单位矩形换算为画布上的像素矩形，
//  统一处理外边框与插槽间距。预览与导出共用同一套几何逻辑，保证所见即所得。
//

import CoreGraphics

enum CollageLayout {

    /// 外观参数（边框/间距/圆角）以「参考画布长边 = 360 点」为基准设定，
    /// 任意画布按此比例缩放，保证预览与导出所见即所得。
    static let referenceLongEdge: CGFloat = 360

    /// 给定画布尺寸，返回外观参数应乘的缩放系数。
    static func scale(forCanvas canvasSize: CGSize) -> CGFloat {
        max(canvasSize.width, canvasSize.height) / referenceLongEdge
    }

    /// 计算某个插槽在画布上的实际矩形（已扣除外边框与间距）。
    /// - Parameters:
    ///   - slot: 模板插槽（单位坐标）。
    ///   - canvasSize: 画布像素尺寸。
    ///   - border: 外边框宽度。
    ///   - spacing: 插槽间距。
    static func frame(for slot: TemplateSlot,
                      canvasSize: CGSize,
                      border: CGFloat,
                      spacing: CGFloat) -> CGRect {
        // 内容区 = 画布去掉四周外边框
        let content = CGRect(x: border,
                             y: border,
                             width: max(0, canvasSize.width - border * 2),
                             height: max(0, canvasSize.height - border * 2))

        // 单位矩形映射到内容区
        var rect = CGRect(
            x: content.minX + slot.rect.minX * content.width,
            y: content.minY + slot.rect.minY * content.height,
            width: slot.rect.width * content.width,
            height: slot.rect.height * content.height
        )

        // 内缩半个间距，相邻插槽合起来即为完整间距
        let half = spacing / 2
        rect = rect.insetBy(dx: half, dy: half)
        if rect.width < 0 { rect.size.width = 0 }
        if rect.height < 0 { rect.size.height = 0 }
        return rect
    }
}
