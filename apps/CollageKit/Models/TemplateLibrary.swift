//
//  TemplateLibrary.swift
//  CollageKit
//
//  内置模板库。涵盖九宫格 / 杂志风 / 胶片风 / 自由四大分类，
//  共 14 套精心排版的模板。免费模板可直接使用，付费模板需解锁 Pro。
//

import SwiftUI

enum TemplateLibrary {

    /// 全部模板。
    static let all: [CollageTemplate] = grid + magazine + film + freeform

    /// 默认模板（首次新建时使用）。
    static var `default`: CollageTemplate { grid.first! }

    static func template(withID id: String) -> CollageTemplate? {
        all.first { $0.id == id }
    }

    static func templates(in category: TemplateCategory) -> [CollageTemplate] {
        all.filter { $0.category == category }
    }

    // MARK: - 九宫格类

    static let grid: [CollageTemplate] = [
        CollageTemplate(
            id: "grid_2x2",
            name: "tpl_grid_2x2",
            category: .grid,
            isPremium: false,
            preferredRatio: .square,
            slots: makeGrid(rows: 2, cols: 2)
        ),
        CollageTemplate(
            id: "grid_3x3",
            name: "tpl_grid_3x3",
            category: .grid,
            isPremium: false,
            preferredRatio: .square,
            slots: makeGrid(rows: 3, cols: 3)
        ),
        CollageTemplate(
            id: "grid_2x3",
            name: "tpl_grid_2x3",
            category: .grid,
            isPremium: false,
            preferredRatio: .portrait,
            slots: makeGrid(rows: 3, cols: 2)
        ),
        CollageTemplate(
            id: "grid_left_big",
            name: "tpl_grid_left_big",
            category: .grid,
            isPremium: true,
            preferredRatio: .square,
            slots: [
                TemplateSlot(0, 0,    0,   0.6, 1.0),
                TemplateSlot(1, 0.6,  0,   0.4, 0.5),
                TemplateSlot(2, 0.6,  0.5, 0.4, 0.5)
            ]
        )
    ]

    // MARK: - 杂志风类

    static let magazine: [CollageTemplate] = [
        CollageTemplate(
            id: "mag_hero_top",
            name: "tpl_mag_hero_top",
            category: .magazine,
            isPremium: false,
            preferredRatio: .portrait,
            slots: [
                TemplateSlot(0, 0,    0,    1.0, 0.55),
                TemplateSlot(1, 0,    0.55, 0.5, 0.45),
                TemplateSlot(2, 0.5,  0.55, 0.5, 0.45)
            ]
        ),
        CollageTemplate(
            id: "mag_sidebar",
            name: "tpl_mag_sidebar",
            category: .magazine,
            isPremium: true,
            preferredRatio: .portrait,
            slots: [
                TemplateSlot(0, 0,    0,    0.65, 1.0),
                TemplateSlot(1, 0.65, 0,    0.35, 0.34),
                TemplateSlot(2, 0.65, 0.34, 0.35, 0.33),
                TemplateSlot(3, 0.65, 0.67, 0.35, 0.33)
            ]
        ),
        CollageTemplate(
            id: "mag_cover",
            name: "tpl_mag_cover",
            category: .magazine,
            isPremium: true,
            preferredRatio: .story,
            slots: [
                TemplateSlot(0, 0,    0,    1.0,  0.7),
                TemplateSlot(1, 0,    0.7,  0.33, 0.3),
                TemplateSlot(2, 0.33, 0.7,  0.34, 0.3),
                TemplateSlot(3, 0.67, 0.7,  0.33, 0.3)
            ]
        )
    ]

    // MARK: - 胶片风类

    static let film: [CollageTemplate] = [
        CollageTemplate(
            id: "film_strip_v",
            name: "tpl_film_strip_v",
            category: .film,
            isPremium: false,
            preferredRatio: .story,
            slots: makeStrip(count: 4, vertical: true)
        ),
        CollageTemplate(
            id: "film_strip_h",
            name: "tpl_film_strip_h",
            category: .film,
            isPremium: true,
            preferredRatio: .portrait,
            slots: makeStrip(count: 3, vertical: false)
        ),
        CollageTemplate(
            id: "film_duo",
            name: "tpl_film_duo",
            category: .film,
            isPremium: false,
            preferredRatio: .square,
            slots: makeStrip(count: 2, vertical: false)
        )
    ]

    // MARK: - 自由类

    static let freeform: [CollageTemplate] = [
        CollageTemplate(
            id: "free_pano",
            name: "tpl_free_pano",
            category: .freeform,
            isPremium: false,
            preferredRatio: .story,
            slots: [
                TemplateSlot(0, 0,    0,    1.0,  0.34),
                TemplateSlot(1, 0,    0.34, 0.55, 0.32),
                TemplateSlot(2, 0.55, 0.34, 0.45, 0.32),
                TemplateSlot(3, 0,    0.66, 1.0,  0.34)
            ]
        ),
        CollageTemplate(
            id: "free_mosaic",
            name: "tpl_free_mosaic",
            category: .freeform,
            isPremium: true,
            preferredRatio: .square,
            slots: [
                TemplateSlot(0, 0,    0,    0.5,  0.5),
                TemplateSlot(1, 0.5,  0,    0.25, 0.5),
                TemplateSlot(2, 0.75, 0,    0.25, 0.5),
                TemplateSlot(3, 0,    0.5,  0.25, 0.5),
                TemplateSlot(4, 0.25, 0.5,  0.25, 0.5),
                TemplateSlot(5, 0.5,  0.5,  0.5,  0.5)
            ]
        ),
        CollageTemplate(
            id: "free_offset",
            name: "tpl_free_offset",
            category: .freeform,
            isPremium: true,
            preferredRatio: .portrait,
            slots: [
                TemplateSlot(0, 0,    0,    0.6,  0.4),
                TemplateSlot(1, 0.6,  0.1,  0.4,  0.4),
                TemplateSlot(2, 0.1,  0.5,  0.4,  0.4),
                TemplateSlot(3, 0.5,  0.6,  0.5,  0.4)
            ]
        )
    ]

    // MARK: - 生成器

    /// 生成均匀网格插槽。
    private static func makeGrid(rows: Int, cols: Int) -> [TemplateSlot] {
        var slots: [TemplateSlot] = []
        let w = 1.0 / CGFloat(cols)
        let h = 1.0 / CGFloat(rows)
        var index = 0
        for r in 0..<rows {
            for c in 0..<cols {
                slots.append(TemplateSlot(index,
                                          CGFloat(c) * w,
                                          CGFloat(r) * h,
                                          w, h))
                index += 1
            }
        }
        return slots
    }

    /// 生成条带（胶片）插槽。
    private static func makeStrip(count: Int, vertical: Bool) -> [TemplateSlot] {
        var slots: [TemplateSlot] = []
        let step = 1.0 / CGFloat(count)
        for i in 0..<count {
            if vertical {
                slots.append(TemplateSlot(i, 0, CGFloat(i) * step, 1.0, step))
            } else {
                slots.append(TemplateSlot(i, CGFloat(i) * step, 0, step, 1.0))
            }
        }
        return slots
    }
}
