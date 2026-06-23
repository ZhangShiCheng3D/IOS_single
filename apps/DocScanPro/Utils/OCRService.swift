//
//  OCRService.swift
//  DocScanPro
//
//  本地 OCR 文字识别服务，基于 Apple Vision 框架。
//  全部计算在设备端完成（neural engine / CPU），无任何网络请求 —— 这是隐私核心。
//

import Foundation
import Vision
import UIKit

/// OCR 识别错误。
enum OCRError: LocalizedError {
    case invalidImage
    case recognitionFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return NSLocalizedString("ocr.error.invalidImage", comment: "无法读取图像")
        case .recognitionFailed(let message):
            return String(
                format: NSLocalizedString("ocr.error.failed", comment: "识别失败：%@"),
                message
            )
        }
    }
}

/// 单次识别结果。
struct OCRResult: Sendable {
    /// 识别出的完整文本。
    let text: String
}

/// 本地 OCR 服务。使用 actor 隔离，保证并发安全。
actor OCRService {

    static let shared = OCRService()

    private init() {}

    /// 识别语言。Vision 支持中英文混排识别。
    /// 顺序影响优先级，中文简体优先以贴合目标用户。
    static let recognitionLanguages = ["zh-Hans", "zh-Hant", "en-US"]

    /// 对单张图像执行本地 OCR。
    /// - Parameter imageData: JPEG/PNG 图像数据。
    /// - Returns: 识别结果，包含拼接文本与文本块数量。
    func recognizeText(in imageData: Data) async throws -> OCRResult {
        guard let uiImage = UIImage(data: imageData),
              let cgImage = uiImage.cgImage else {
            throw OCRError.invalidImage
        }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(throwing: OCRError.recognitionFailed(error.localizedDescription))
                    return
                }

                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: OCRResult(text: ""))
                    return
                }

                // 取每个文本块的最高置信度候选，按从上到下、从左到右的视觉顺序拼接。
                let lines = observations
                    .sorted { lhs, rhs in
                        // boundingBox 原点在左下角，y 越大越靠上。
                        if abs(lhs.boundingBox.midY - rhs.boundingBox.midY) > 0.02 {
                            return lhs.boundingBox.midY > rhs.boundingBox.midY
                        }
                        return lhs.boundingBox.minX < rhs.boundingBox.minX
                    }
                    .compactMap { $0.topCandidates(1).first?.string }

                let text = lines.joined(separator: "\n")
                continuation.resume(returning: OCRResult(text: text))
            }

            // accurate 模式精度更高，适合文档场景；languageCorrection 提升中文准确率。
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.recognitionLanguages = Self.recognitionLanguages

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: OCRError.recognitionFailed(error.localizedDescription))
            }
        }
    }
}
