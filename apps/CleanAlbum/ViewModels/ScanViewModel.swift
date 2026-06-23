//
//  ScanViewModel.swift
//  CleanAlbum
//
//  扫描流程编排：权限 → 取图 → 端侧分析 → 分组 → 清理。
//

import Foundation
@preconcurrency import Photos   // PHAsset 未标注 Sendable；跨 PhotoLibraryManager actor 传递时降级为兼容模式
import SwiftUI
import UIKit
import Observation

/// 扫描阶段。
enum ScanPhase: Equatable {
    case idle
    case requestingPermission
    case fetching
    case analyzing(progress: Double)   // 0...1
    case grouping
    case done
    case noAccess
    case empty
}

@MainActor
@Observable
final class ScanViewModel {

    // MARK: - 依赖

    private let library = PhotoLibraryManager()
    private let analyzer = PhotoAnalyzer()

    /// 当前扫描任务句柄，用于支持用户中途取消（大相册可能耗时数十秒）。
    private var scanTask: Task<Void, Never>?

    // MARK: - 状态

    var phase: ScanPhase = .idle

    /// 全部分组结果。
    var groups: [PhotoGroup] = []

    /// 扫描的照片总数。
    private(set) var totalScanned: Int = 0

    /// 设备容量快照（扫描时记录，用于清理后对比）。
    private(set) var storageBefore: (total: Int64, free: Int64) = (0, 0)

    /// 可调阈值（来自 AppSettings，注入）。
    var similarityThreshold: Double = 0.85
    var blurSensitivity: Double = 0.5

    // MARK: - 派生数据

    func groups(of kind: PhotoGroupKind) -> [PhotoGroup] {
        groups.filter { $0.kind == kind }
    }

    func count(of kind: PhotoGroupKind) -> Int {
        groups(of: kind).reduce(0) { $0 + $1.items.count }
    }

    /// 全部可清理（建议删除）照片可释放空间总量。
    var totalReclaimableBytes: Int64 {
        groups.reduce(0) { $0 + $1.reclaimableBytes }
    }

    /// 当前用户选中的待删除照片数。
    var selectedCount: Int {
        groups.reduce(0) { $0 + $1.selectedItems.count }
    }

    var isScanning: Bool {
        switch phase {
        case .requestingPermission, .fetching, .analyzing, .grouping: return true
        default: return false
        }
    }

    // MARK: - 阈值映射

    /// 把 UI 的 0...1 相似度阈值映射到 VNFeaturePrint 距离阈值。
    /// 用户调高"相似度要求" → 距离阈值变小 → 仅极相似才入组。
    private var similarDistanceThreshold: Float {
        // 经验范围：距离 0（完全相同）~ 1.5（明显不同）。
        // threshold 0.5 → 距离 1.0；threshold 1.0 → 距离 0.3。
        let t = Float(similarityThreshold)
        return Float(1.3 - t * 1.0)   // 0.85 → ~0.45
    }

    private var duplicateDistanceThreshold: Float {
        // 重复判定更严格，约为相似阈值的一半。
        similarDistanceThreshold * 0.5
    }

    /// 模糊阈值：sensitivity 越高，阈值越高（更多照片被判模糊）。
    private var sharpnessThreshold: Double {
        // Laplacian 方差经验范围约 5（很模糊）~ 200（清晰）。
        50 + blurSensitivity * 250   // 0.5 → 175
    }

    // MARK: - 主流程

    /// 执行完整扫描（可被 `cancelScan()` 中途取消）。
    func scan() async {
        scanTask?.cancel()
        let task = Task { await performScan() }
        scanTask = task
        await task.value
    }

    /// 取消正在进行的扫描，恢复到初始状态。
    func cancelScan() {
        scanTask?.cancel()
        scanTask = nil
        phase = .idle
    }

    private func performScan() async {
        // 1. 权限
        phase = .requestingPermission
        let status = await library.requestAuthorization()
        guard status == .authorized || status == .limited else {
            phase = .noAccess
            return
        }
        if Task.isCancelled { phase = .idle; return }

        // 2. 容量快照
        storageBefore = library.deviceStorage()

        // 3. 取图
        phase = .fetching
        let assets = library.fetchAllPhotos()
        totalScanned = assets.count
        guard !assets.isEmpty else {
            phase = .empty
            return
        }

        // 4. 构建 PhotoItem 并逐张分析
        var items: [PhotoItem] = []
        items.reserveCapacity(assets.count)

        let total = assets.count
        for (index, asset) in assets.enumerated() {
            // 每张照片前检查取消，确保大相册能即时响应"取消"。
            if Task.isCancelled { phase = .idle; return }

            let item = PhotoItem(asset: asset)
            item.byteSize = library.byteSize(of: asset)

            if let image = await library.analysisImage(for: asset) {
                item.featurePrint = await analyzer.featurePrint(for: image)
                item.sharpnessScore = await analyzer.sharpness(for: image)
            }
            items.append(item)

            if index % 5 == 0 || index == total - 1 {
                phase = .analyzing(progress: Double(index + 1) / Double(total))
            }
        }

        if Task.isCancelled { phase = .idle; return }

        // 5. 分组
        phase = .grouping
        var result: [PhotoGroup] = []

        let similarGroups = await analyzer.groupBySimilarity(
            items: items,
            duplicateThreshold: duplicateDistanceThreshold,
            similarThreshold: similarDistanceThreshold
        )
        result.append(contentsOf: similarGroups)

        // 模糊检测：排除已进入相似/重复组的照片，避免重复出现。
        let groupedIDs = Set(similarGroups.flatMap { $0.items.map(\.id) })
        let ungrouped = items.filter { !groupedIDs.contains($0.id) }
        if let blurry = await analyzer.blurryGroup(items: ungrouped, sharpnessThreshold: sharpnessThreshold) {
            result.append(blurry)
        }

        if Task.isCancelled { phase = .idle; return }

        // 6. 应用默认选择
        for group in result {
            group.applyDefaultSelection()
        }

        groups = result
        phase = result.isEmpty ? .empty : .done
    }

    // MARK: - 清理

    /// 删除所有选中的照片。返回结果（删除数、释放字节）。
    /// - Throws: 删除失败（用户取消系统确认框时抛出）。
    @discardableResult
    func deleteSelected() async throws -> (count: Int, freed: Int64) {
        let selected = groups.flatMap { $0.selectedItems }
        guard !selected.isEmpty else { return (0, 0) }

        let assets = selected.map { $0.asset }
        let freed = selected.reduce(Int64(0)) { $0 + $1.byteSize }

        try await library.delete(assets: assets)

        // 从分组中移除已删项；清空空组。
        let deletedIDs = Set(selected.map(\.id))
        for group in groups {
            group.items.removeAll { deletedIDs.contains($0.id) }
        }
        groups.removeAll { $0.items.count < 1 }

        return (selected.count, freed)
    }

    /// 取某照片的缩略图（供 View 调用）。
    func thumbnail(for item: PhotoItem, size: CGSize) async -> UIImage? {
        await library.thumbnail(for: item.asset, targetSize: size)
    }
}
