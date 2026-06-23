//
//  PhotoLibrary.swift
//  ShotFrame
//
//  Thin wrapper around Photos for saving exported images, with clear error
//  surfaces so the UI can explain failures to the user.
//

import Photos
import UIKit

enum PhotoLibraryError: LocalizedError {
    case permissionDenied
    case saveFailed(String)

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return NSLocalizedString("error.photo.permission", comment: "")
        case .saveFailed(let message):
            return message
        }
    }
}

enum PhotoLibrary {

    /// Request add-only authorization, returning whether saving is allowed.
    static func ensureAddPermission() async -> Bool {
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        switch status {
        case .authorized, .limited:
            return true
        case .notDetermined:
            let newStatus = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
            return newStatus == .authorized || newStatus == .limited
        default:
            return false
        }
    }

    /// Save a single image to the user's photo library.
    static func save(_ image: UIImage) async throws {
        guard await ensureAddPermission() else {
            throw PhotoLibraryError.permissionDenied
        }
        do {
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }
        } catch {
            throw PhotoLibraryError.saveFailed(error.localizedDescription)
        }
    }

    /// Save many images, throwing on the first failure.
    static func save(_ images: [UIImage]) async throws {
        guard await ensureAddPermission() else {
            throw PhotoLibraryError.permissionDenied
        }
        do {
            try await PHPhotoLibrary.shared().performChanges {
                for image in images {
                    PHAssetChangeRequest.creationRequestForAsset(from: image)
                }
            }
        } catch {
            throw PhotoLibraryError.saveFailed(error.localizedDescription)
        }
    }
}
