//
//  PhotoLibraryManager.swift
//  CleanAlbum
//
//  封装 Photos 框架：权限、取图、删除、容量统计。
//

import Foundation
import Photos
import UIKit

/// 相册访问与管理。所有方法均为本地操作，零网络。
actor PhotoLibraryManager {

    private let imageManager = PHCachingImageManager()

    // MARK: - 权限

    /// 请求相册读写权限，返回当前授权状态。
    nonisolated func requestAuthorization() async -> PHAuthorizationStatus {
        await withCheckedContinuation { continuation in
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
                continuation.resume(returning: status)
            }
        }
    }

    nonisolated var authorizationStatus: PHAuthorizationStatus {
        PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }

    // MARK: - 取资源

    /// 抓取相册中全部照片（按创建时间倒序）。
    nonisolated func fetchAllPhotos() -> [PHAsset] {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        options.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
        let result = PHAsset.fetchAssets(with: options)
        var assets: [PHAsset] = []
        assets.reserveCapacity(result.count)
        result.enumerateObjects { asset, _, _ in assets.append(asset) }
        return assets
    }

    // MARK: - 缩略图 / 全图

    /// 异步取缩略图。
    func thumbnail(for asset: PHAsset, targetSize: CGSize) async -> UIImage? {
        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.resizeMode = .fast
        options.isNetworkAccessAllowed = false   // 隐私优先：不触发 iCloud 下载
        options.isSynchronous = false

        return await withCheckedContinuation { continuation in
            var resumed = false
            imageManager.requestImage(
                for: asset,
                targetSize: targetSize,
                contentMode: .aspectFill,
                options: options
            ) { image, info in
                // opportunistic 可能多次回调，仅在最终结果时 resume。
                let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false
                if !isDegraded && !resumed {
                    resumed = true
                    continuation.resume(returning: image)
                }
            }
        }
    }

    /// 取用于分析的中等尺寸图（平衡精度与性能）。
    func analysisImage(for asset: PHAsset) async -> UIImage? {
        await thumbnail(for: asset, targetSize: CGSize(width: 256, height: 256))
    }

    // MARK: - 文件大小

    /// 精确取资源占用字节（通过 PHAssetResource）。
    nonisolated func byteSize(of asset: PHAsset) -> Int64 {
        let resources = PHAssetResource.assetResources(for: asset)
        for resource in resources {
            if let size = resource.value(forKey: "fileSize") as? CLongLong {
                return Int64(size)
            }
        }
        // 兜底：按像素估算（约每像素 3 字节，JPEG 压缩比 ~10）。
        let pixels = Int64(asset.pixelWidth * asset.pixelHeight)
        return max(pixels * 3 / 10, 50_000)
    }

    // MARK: - 删除

    /// 删除一批照片（系统会弹出确认框；删除后进入"最近删除"）。
    /// - Returns: 是否成功。
    func delete(assets: [PHAsset]) async throws {
        guard !assets.isEmpty else { return }
        try await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.deleteAssets(assets as NSArray)
        }
    }

    // MARK: - 设备容量

    /// 设备存储统计：总量与可用量。
    nonisolated func deviceStorage() -> (total: Int64, free: Int64) {
        let url = URL(fileURLWithPath: NSHomeDirectory())
        do {
            let values = try url.resourceValues(forKeys: [
                .volumeTotalCapacityKey,
                .volumeAvailableCapacityForImportantUsageKey
            ])
            let total = Int64(values.volumeTotalCapacity ?? 0)
            let free = values.volumeAvailableCapacityForImportantUsage ?? 0
            return (total, free)
        } catch {
            return (0, 0)
        }
    }
}
