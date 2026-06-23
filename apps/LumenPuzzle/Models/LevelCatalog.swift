//
//  LevelCatalog.swift
//  LumenPuzzle
//
//  10 个内置关卡的设计，由易到难。
//  设计原则：
//   - Easy（1-3）：单目标，0~1 个障碍，建立"移动光源越过遮挡"的直觉。
//   - Medium（4-7）：双目标或迷宫式障碍，需要权衡光源落点。
//   - Hard（8-10）：多目标 + 复杂遮挡，存在唯一或极窄的解空间。
//

import Foundation
import SceneKit

enum LevelCatalog {

    /// 全部关卡（按 id 升序）。
    static let all: [Level] = [
        level1, level2, level3, level4, level5,
        level6, level7, level8, level9, level10
    ]

    /// 关卡总数。
    static var count: Int { all.count }

    /// 按 id 取关卡。
    static func level(id: Int) -> Level? {
        all.first { $0.id == id }
    }

    /// 标准光源移动范围（覆盖大部分关卡地台）。
    private static func bounds(_ half: Float, height: Float = 7) -> LightBounds {
        LightBounds(minX: -half, maxX: half, minZ: -half, maxZ: half, height: height)
    }

    // MARK: - Easy

    static let level1 = Level(
        id: 1,
        nameKey: "level.1.name",
        difficulty: .easy,
        platformSize: SCNVector3(14, 0.6, 14),
        obstacles: [],
        targets: [
            LightTarget(position: SCNVector3(0, 0.5, 0))
        ],
        lightStart: SCNVector3(-4, 7, 4),
        lightBounds: bounds(6),
        hintKey: "level.1.hint"
    )

    static let level2 = Level(
        id: 2,
        nameKey: "level.2.name",
        difficulty: .easy,
        platformSize: SCNVector3(14, 0.6, 14),
        obstacles: [
            Obstacle(position: SCNVector3(0, 1.5, 0), size: SCNVector3(2, 3, 2))
        ],
        targets: [
            LightTarget(position: SCNVector3(0, 0.5, 3.5))
        ],
        lightStart: SCNVector3(0, 7, -5),
        lightBounds: bounds(6),
        hintKey: "level.2.hint"
    )

    static let level3 = Level(
        id: 3,
        nameKey: "level.3.name",
        difficulty: .easy,
        platformSize: SCNVector3(16, 0.6, 16),
        obstacles: [
            Obstacle(position: SCNVector3(-2.5, 2, 0), size: SCNVector3(1.5, 4, 6))
        ],
        targets: [
            LightTarget(position: SCNVector3(-5, 0.5, 0))
        ],
        lightStart: SCNVector3(4, 7, 0),
        lightBounds: bounds(7),
        hintKey: "level.3.hint"
    )

    // MARK: - Medium

    static let level4 = Level(
        id: 4,
        nameKey: "level.4.name",
        difficulty: .medium,
        platformSize: SCNVector3(16, 0.6, 16),
        obstacles: [
            Obstacle(position: SCNVector3(0, 2, 0), size: SCNVector3(2.5, 4, 2.5))
        ],
        targets: [
            LightTarget(position: SCNVector3(4, 0.5, 4)),
            LightTarget(position: SCNVector3(-4, 0.5, -4))
        ],
        lightStart: SCNVector3(0, 7, 6),
        lightBounds: bounds(7),
        hintKey: "level.4.hint"
    )

    static let level5 = Level(
        id: 5,
        nameKey: "level.5.name",
        difficulty: .medium,
        platformSize: SCNVector3(18, 0.6, 18),
        obstacles: [
            Obstacle(position: SCNVector3(-3, 2, 0), size: SCNVector3(1.4, 4, 8)),
            Obstacle(position: SCNVector3(3, 2, 0), size: SCNVector3(1.4, 4, 8))
        ],
        targets: [
            LightTarget(position: SCNVector3(0, 0.5, 0))
        ],
        lightStart: SCNVector3(0, 7, 7),
        lightBounds: bounds(8),
        hintKey: "level.5.hint"
    )

    static let level6 = Level(
        id: 6,
        nameKey: "level.6.name",
        difficulty: .medium,
        platformSize: SCNVector3(18, 0.6, 18),
        obstacles: [
            Obstacle(position: SCNVector3(0, 2, 3), size: SCNVector3(8, 4, 1.4)),
            Obstacle(position: SCNVector3(0, 2, -3), size: SCNVector3(8, 4, 1.4))
        ],
        targets: [
            LightTarget(position: SCNVector3(0, 0.5, 0)),
            LightTarget(position: SCNVector3(6, 0.5, 0))
        ],
        lightStart: SCNVector3(-6, 7, 0),
        lightBounds: bounds(8),
        hintKey: "level.6.hint"
    )

    static let level7 = Level(
        id: 7,
        nameKey: "level.7.name",
        difficulty: .medium,
        platformSize: SCNVector3(20, 0.6, 20),
        obstacles: [
            Obstacle(position: SCNVector3(-4, 2, -2), size: SCNVector3(2, 4, 2)),
            Obstacle(position: SCNVector3(4, 2, -2), size: SCNVector3(2, 4, 2)),
            Obstacle(position: SCNVector3(0, 2, 4), size: SCNVector3(2, 4, 2))
        ],
        targets: [
            LightTarget(position: SCNVector3(-4, 0.5, 4)),
            LightTarget(position: SCNVector3(4, 0.5, 4)),
            LightTarget(position: SCNVector3(0, 0.5, -4))
        ],
        lightStart: SCNVector3(0, 7, 0),
        lightBounds: bounds(9),
        hintKey: "level.7.hint"
    )

    // MARK: - Hard

    static let level8 = Level(
        id: 8,
        nameKey: "level.8.name",
        difficulty: .hard,
        platformSize: SCNVector3(20, 0.6, 20),
        obstacles: [
            Obstacle(position: SCNVector3(0, 2, 0), size: SCNVector3(2, 4, 10)),
            Obstacle(position: SCNVector3(-5, 2, 0), size: SCNVector3(2, 4, 2)),
            Obstacle(position: SCNVector3(5, 2, 0), size: SCNVector3(2, 4, 2))
        ],
        targets: [
            LightTarget(position: SCNVector3(-7, 0.5, 0)),
            LightTarget(position: SCNVector3(7, 0.5, 0))
        ],
        lightStart: SCNVector3(0, 7, 8),
        lightBounds: bounds(9),
        hintKey: "level.8.hint"
    )

    static let level9 = Level(
        id: 9,
        nameKey: "level.9.name",
        difficulty: .hard,
        platformSize: SCNVector3(22, 0.6, 22),
        obstacles: [
            Obstacle(position: SCNVector3(-3, 2, -3), size: SCNVector3(6, 4, 1.4)),
            Obstacle(position: SCNVector3(3, 2, 3), size: SCNVector3(6, 4, 1.4)),
            Obstacle(position: SCNVector3(0, 2, 0), size: SCNVector3(1.4, 4, 6), rotationY: .pi / 4)
        ],
        targets: [
            LightTarget(position: SCNVector3(-6, 0.5, 4)),
            LightTarget(position: SCNVector3(6, 0.5, -4)),
            LightTarget(position: SCNVector3(0, 0.5, 7))
        ],
        lightStart: SCNVector3(0, 7, -7),
        lightBounds: bounds(10),
        hintKey: "level.9.hint"
    )

    static let level10 = Level(
        id: 10,
        nameKey: "level.10.name",
        difficulty: .hard,
        platformSize: SCNVector3(24, 0.6, 24),
        obstacles: [
            Obstacle(position: SCNVector3(0, 2.5, 0), size: SCNVector3(3, 5, 3)),
            Obstacle(position: SCNVector3(-6, 2, 0), size: SCNVector3(1.4, 4, 8)),
            Obstacle(position: SCNVector3(6, 2, 0), size: SCNVector3(1.4, 4, 8)),
            Obstacle(position: SCNVector3(0, 2, 6), size: SCNVector3(8, 4, 1.4)),
            Obstacle(position: SCNVector3(0, 2, -6), size: SCNVector3(8, 4, 1.4))
        ],
        targets: [
            LightTarget(position: SCNVector3(-8.5, 0.5, 0)),
            LightTarget(position: SCNVector3(8.5, 0.5, 0)),
            LightTarget(position: SCNVector3(0, 0.5, 8.5)),
            LightTarget(position: SCNVector3(0, 0.5, -8.5))
        ],
        lightStart: SCNVector3(0, 8, 0),
        lightBounds: bounds(11, height: 8),
        hintKey: "level.10.hint"
    )
}
