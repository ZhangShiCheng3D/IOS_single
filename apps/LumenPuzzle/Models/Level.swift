//
//  Level.swift
//  LumenPuzzle
//
//  关卡定义（值类型）。描述一个 3D 光影解谜场景的全部几何要素：
//  地台、障碍物、目标点、光源初始位置与可移动范围。
//  这些数据被 PuzzleSceneBuilder 转换为真正的 SceneKit 场景。
//

import Foundation
import SceneKit

/// 难度分级（用于关卡选择界面着色与成就判定）。
enum Difficulty: Int, CaseIterable, Codable {
    case easy
    case medium
    case hard

    var titleKey: String {
        switch self {
        case .easy:   return "difficulty.easy"
        case .medium: return "difficulty.medium"
        case .hard:   return "difficulty.hard"
        }
    }
}

/// 一个障碍方块：会遮挡光线，制造阴影。
struct Obstacle: Identifiable {
    let id = UUID()
    /// 中心位置。
    var position: SCNVector3
    /// 尺寸（宽、高、深）。
    var size: SCNVector3
    /// 绕 Y 轴旋转角度（弧度），用于斜置墙体。
    var rotationY: Float = 0
}

/// 一个待点亮的目标。当光源对其形成无遮挡直射且足够近时即被照亮。
struct LightTarget: Identifiable {
    let id = UUID()
    /// 目标中心位置。
    var position: SCNVector3
    /// 判定为「被照亮」所需的最大光源距离。超过则视为太远、光太弱。
    var maxLitDistance: Float = 9.0
}

/// 光源可移动的范围（一个轴对齐的水平矩形区域，固定高度）。
struct LightBounds {
    var minX: Float
    var maxX: Float
    var minZ: Float
    var maxZ: Float
    /// 光源所在的固定高度（Y）。
    var height: Float

    func clamp(_ p: SCNVector3) -> SCNVector3 {
        SCNVector3(
            x: Swift.min(Swift.max(p.x, minX), maxX),
            y: height,
            z: Swift.min(Swift.max(p.z, minZ), maxZ)
        )
    }
}

/// 关卡完整定义。
struct Level: Identifiable {
    let id: Int
    let nameKey: String
    let difficulty: Difficulty

    /// 地台尺寸（用于渲染地面与边界视觉）。
    var platformSize: SCNVector3

    /// 障碍物集合。
    var obstacles: [Obstacle]

    /// 目标集合（全部点亮即通关）。
    var targets: [LightTarget]

    /// 光源初始位置。
    var lightStart: SCNVector3

    /// 光源可移动范围。
    var lightBounds: LightBounds

    /// 关卡提示（本地化键）。
    var hintKey: String
}
