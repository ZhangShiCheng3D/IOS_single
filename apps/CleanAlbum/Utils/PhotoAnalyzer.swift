//
//  PhotoAnalyzer.swift
//  CleanAlbum
//
//  端侧图像分析引擎：相似度比对（VNFeaturePrint）+ 模糊检测。
//  全部计算在设备本地完成，绝不上传任何照片或特征。
//

import Foundation
import Vision
import CoreImage
import UIKit

/// 端侧分析引擎。隔离为 actor，串行执行 Vision 请求，避免内存峰值。
actor PhotoAnalyzer {

    /// 复用同一个 CIContext（创建开销大）。
    private let ciContext = CIContext(options: [.useSoftwareRenderer: false])

    // MARK: - 特征向量

    /// 计算单张图像的 VNFeaturePrintObservation，用于相似度比对。
    ///
    /// 这是隐私核心：只生成抽象特征向量，不离开设备。
    func featurePrint(for image: UIImage) -> VNFeaturePrintObservationData? {
        guard let cgImage = image.cgImage else { return nil }
        let request = VNGenerateImageFeaturePrintRequest()
        // 使用较小的图像裁剪以提速；scaleFit 保留主体。
        request.imageCropAndScaleOption = .scaleFit

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([request])
            guard let observation = request.results?.first else { return nil }
            return VNFeaturePrintObservationData(observation: observation)
        } catch {
            return nil
        }
    }

    // MARK: - 模糊检测

    /// 计算清晰度评分：Laplacian 算子响应的方差。
    ///
    /// 这是业界标准的免训练模糊检测法 —— 清晰图像边缘丰富、方差大；
    /// 模糊图像边缘平滑、方差小。配合 VNGenerateImageFeaturePrint 的特征，
    /// 完全在端侧完成，无需任何模型下载。
    func sharpness(for image: UIImage) -> Double {
        guard let cgImage = image.cgImage else { return 0 }
        let input = CIImage(cgImage: cgImage)

        // 1. 转灰度，降低色彩干扰。
        guard let grayFilter = CIFilter(name: "CIPhotoEffectMono") else { return 0 }
        grayFilter.setValue(input, forKey: kCIInputImageKey)
        guard let gray = grayFilter.outputImage else { return 0 }

        // 2. 应用 Laplacian 卷积（边缘检测）。
        guard let edges = applyLaplacian(to: gray) else { return 0 }

        // 3. 渲染为像素并计算方差。
        return variance(of: edges)
    }

    /// 用 3x3 Laplacian 核做卷积。
    private func applyLaplacian(to image: CIImage) -> CIImage? {
        // 标准 Laplacian 核：中心 8，周围 -1。
        let weights = CIVector(values: [
            -1, -1, -1,
            -1,  8, -1,
            -1, -1, -1
        ], count: 9)
        guard let filter = CIFilter(name: "CIConvolution3X3") else { return nil }
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(weights, forKey: "inputWeights")
        filter.setValue(0, forKey: "inputBias")
        return filter.outputImage
    }

    /// 渲染 CIImage 的亮度方差。方差越大越清晰。
    private func variance(of image: CIImage) -> Double {
        // 缩放到固定小尺寸以稳定指标并提速。
        let extent = CGRect(x: 0, y: 0, width: 64, height: 64)
        let scaled = image.transformed(by: CGAffineTransform(
            scaleX: 64 / max(image.extent.width, 1),
            y: 64 / max(image.extent.height, 1)
        ))

        let width = 64, height = 64
        var bitmap = [UInt8](repeating: 0, count: width * height * 4)
        ciContext.render(
            scaled,
            toBitmap: &bitmap,
            rowBytes: width * 4,
            bounds: extent,
            format: .RGBA8,
            colorSpace: CGColorSpaceCreateDeviceRGB()
        )

        // 取 R 通道（灰度图三通道一致）计算方差。
        var sum: Double = 0
        var sumSq: Double = 0
        let count = width * height
        for i in 0..<count {
            let v = Double(bitmap[i * 4])
            sum += v
            sumSq += v * v
        }
        let mean = sum / Double(count)
        let varValue = sumSq / Double(count) - mean * mean
        return max(0, varValue)
    }

    // MARK: - 分组

    /// 根据特征向量距离把照片聚类成"相似/重复"组。
    ///
    /// - Parameters:
    ///   - items: 已计算特征向量的照片。
    ///   - duplicateThreshold: 判定"重复"的距离上限（更小=更相似）。
    ///   - similarThreshold: 判定"相似"的距离上限。
    /// - Returns: 分组数组（仅含 2 张及以上的组）。
    func groupBySimilarity(
        items: [PhotoItem],
        duplicateThreshold: Float,
        similarThreshold: Float
    ) -> [PhotoGroup] {

        let candidates = items.filter { $0.featurePrint != nil }
        var visited = Set<String>()
        var groups: [PhotoGroup] = []

        for i in 0..<candidates.count {
            let anchor = candidates[i]
            if visited.contains(anchor.id) { continue }
            guard let anchorPrint = anchor.featurePrint else { continue }

            var members: [PhotoItem] = [anchor]
            var maxDistanceInGroup: Float = 0

            for j in (i + 1)..<candidates.count {
                let other = candidates[j]
                if visited.contains(other.id) { continue }
                guard let otherPrint = other.featurePrint,
                      let distance = anchorPrint.distance(to: otherPrint) else { continue }

                if distance <= similarThreshold {
                    members.append(other)
                    visited.insert(other.id)
                    maxDistanceInGroup = max(maxDistanceInGroup, distance)
                }
            }

            if members.count >= 2 {
                visited.insert(anchor.id)
                // 组内最大距离很小 → 重复；否则 → 相似。
                let kind: PhotoGroupKind = maxDistanceInGroup <= duplicateThreshold ? .duplicate : .similar
                let group = PhotoGroup(kind: kind, items: members)
                groups.append(group)
            }
        }
        return groups
    }

    /// 把低于清晰度阈值的照片收集为"模糊"组（每张独立一项）。
    func blurryGroup(items: [PhotoItem], sharpnessThreshold: Double) -> PhotoGroup? {
        let blurry = items.filter { ($0.sharpnessScore ?? .greatestFiniteMagnitude) < sharpnessThreshold }
        guard !blurry.isEmpty else { return nil }
        return PhotoGroup(kind: .blurry, items: blurry)
    }
}
