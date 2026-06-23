//
//  PhotoItem.swift
//  CleanAlbum
//
//  运行期照片模型（不持久化）。包裹 PHAsset 与分析结果。
//

import Foundation
import Photos
import Vision

/// 单张照片的运行期表示。
///
/// 不写入 SwiftData：相册本身是事实来源，每次扫描重新构建，避免数据陈旧。
///
/// 标记 `@unchecked Sendable`：实例在 `PhotoAnalyzer` actor 内写入分析结果、
/// 在 MainActor 读取展示，访问有明确时序（分析完成后才分组/展示），不存在数据竞争。
@Observable
final class PhotoItem: Identifiable, Hashable, @unchecked Sendable {

    /// PHAsset 的本地标识符，作为稳定 id。
    let id: String

    /// 底层相册资源。
    let asset: PHAsset

    /// 估算占用字节数。
    var byteSize: Int64

    /// Vision 特征向量（VNFeaturePrintObservation 原始数据），用于相似度比对。
    var featurePrint: VNFeaturePrintObservationData?

    /// 清晰度评分（Laplacian 方差）。值越低越模糊。nil 表示尚未计算。
    var sharpnessScore: Double?

    /// 用户是否选中（待删除）。
    var isSelected: Bool = false

    init(asset: PHAsset) {
        self.id = asset.localIdentifier
        self.asset = asset
        // PHAsset 不直接暴露文件大小，按像素估算（见 PhotoLibraryManager 精确取值）。
        self.byteSize = 0
    }

    static func == (lhs: PhotoItem, rhs: PhotoItem) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

/// VNFeaturePrintObservation 的可比对包裹。
///
/// 直接持有 observation 以便调用其 computeDistance；分离成结构体方便跨 actor 传递。
/// `@unchecked Sendable`：observation 生成后只读，computeDistance 不修改其状态。
struct VNFeaturePrintObservationData: @unchecked Sendable {
    let observation: VNFeaturePrintObservation

    /// 计算与另一特征向量的距离（越小越相似）。
    func distance(to other: VNFeaturePrintObservationData) -> Float? {
        var distance: Float = 0
        do {
            try observation.computeDistance(&distance, to: other.observation)
            return distance
        } catch {
            return nil
        }
    }
}
