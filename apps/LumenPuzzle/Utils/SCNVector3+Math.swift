//
//  SCNVector3+Math.swift
//  LumenPuzzle
//
//  SceneKit 向量数学辅助。用于光源—目标的距离与方向计算。
//

import SceneKit

extension SCNVector3 {

    /// 向量长度。
    var length: Float {
        sqrtf(x * x + y * y + z * z)
    }

    /// 到另一点的欧氏距离。
    func distance(to other: SCNVector3) -> Float {
        (self - other).length
    }

    /// 归一化（零向量安全）。
    var normalized: SCNVector3 {
        let len = length
        guard len > 1e-6 else { return SCNVector3(0, 0, 0) }
        return SCNVector3(x / len, y / len, z / len)
    }

    static func - (lhs: SCNVector3, rhs: SCNVector3) -> SCNVector3 {
        SCNVector3(lhs.x - rhs.x, lhs.y - rhs.y, lhs.z - rhs.z)
    }

    static func + (lhs: SCNVector3, rhs: SCNVector3) -> SCNVector3 {
        SCNVector3(lhs.x + rhs.x, lhs.y + rhs.y, lhs.z + rhs.z)
    }

    static func * (lhs: SCNVector3, scalar: Float) -> SCNVector3 {
        SCNVector3(lhs.x * scalar, lhs.y * scalar, lhs.z * scalar)
    }
}
