//
//  AppSettings.swift
//  CleanAlbum
//
//  用户可调的扫描设置，持久化于 SwiftData。
//

import Foundation
import SwiftData

/// 全局应用设置（单实例）。
@Model
final class AppSettings {

    /// 相似度阈值（0.0 – 1.0）。值越高表示要求越严格（越相似才算重复）。
    /// 默认 0.85，对应 VNFeaturePrint 距离阈值的经验值。
    var similarityThreshold: Double

    /// 模糊检测灵敏度（0.0 – 1.0）。值越高越容易把照片判定为模糊。
    var blurSensitivity: Double

    /// 是否在分组中默认保留每组中“质量最佳”的一张。
    var keepBestByDefault: Bool

    /// 创建时间。
    var createdAt: Date

    init(
        similarityThreshold: Double = 0.85,
        blurSensitivity: Double = 0.5,
        keepBestByDefault: Bool = true,
        createdAt: Date = .now
    ) {
        self.similarityThreshold = similarityThreshold
        self.blurSensitivity = blurSensitivity
        self.keepBestByDefault = keepBestByDefault
        self.createdAt = createdAt
    }
}
