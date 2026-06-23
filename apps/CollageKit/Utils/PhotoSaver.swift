//
//  PhotoSaver.swift
//  CollageKit
//
//  把渲染好的图片写入系统相册。使用 UIImageWriteToSavedPhotosAlbum，
//  需在 Info.plist 配置 NSPhotoLibraryAddUsageDescription。
//

import UIKit

@MainActor
final class PhotoSaver: NSObject {

    enum SaveError: LocalizedError {
        case failed(String)
        var errorDescription: String? {
            switch self {
            case .failed(let msg): return msg
            }
        }
    }

    private var continuation: CheckedContinuation<Void, Error>?

    /// 异步保存图片到相册，成功返回，失败抛错。
    func save(_ image: UIImage) async throws {
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            self.continuation = cont
            UIImageWriteToSavedPhotosAlbum(
                image,
                self,
                #selector(image(_:didFinishSavingWithError:contextInfo:)),
                nil
            )
        }
    }

    @objc private func image(_ image: UIImage,
                             didFinishSavingWithError error: Error?,
                             contextInfo: UnsafeRawPointer) {
        if let error {
            continuation?.resume(throwing: SaveError.failed(error.localizedDescription))
        } else {
            continuation?.resume(returning: ())
        }
        continuation = nil
    }
}
