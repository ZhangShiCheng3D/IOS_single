//
//  PhotoStorage.swift
//  RetroFilm
//
//  Disk-backed storage for captured images. SwiftData holds metadata + file
//  names; the heavy JPEG bytes live here under Documents/Photos. Keeping pixels
//  out of the database keeps the store small and queries fast.
//

import Foundation
import UIKit

enum PhotoStorageError: Error, LocalizedError {
    case encodingFailed
    case writeFailed(String)
    case notFound

    var errorDescription: String? {
        switch self {
        case .encodingFailed: return NSLocalizedString("error.encode", comment: "")
        case .writeFailed(let p): return "Failed to write file at \(p)"
        case .notFound: return NSLocalizedString("error.notFound", comment: "")
        }
    }
}

struct PhotoStorage {

    static let shared = PhotoStorage()

    /// Documents/Photos — created lazily on first write.
    private var photosDirectory: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("Photos", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    func url(for fileName: String) -> URL {
        photosDirectory.appendingPathComponent(fileName)
    }

    // MARK: Write

    /// Persists original, rendered, and a thumbnail. Returns the three file
    /// names to store in the `CapturedPhoto` model.
    func save(original: UIImage,
              rendered: UIImage,
              id: UUID) throws -> (original: String, rendered: String, thumbnail: String) {
        let originalName = "\(id.uuidString)_orig.jpg"
        let renderedName = "\(id.uuidString)_render.jpg"
        let thumbName = "\(id.uuidString)_thumb.jpg"

        try write(original, quality: 0.92, to: originalName)
        try write(rendered, quality: 0.95, to: renderedName)

        let thumb = rendered.downscaled(toMaxDimension: 400)
        try write(thumb, quality: 0.8, to: thumbName)

        return (originalName, renderedName, thumbName)
    }

    /// Overwrites the rendered + thumbnail files after a re-edit, keeping the
    /// original intact for further non-destructive edits.
    func updateRender(_ rendered: UIImage, id: UUID) throws -> (rendered: String, thumbnail: String) {
        let renderedName = "\(id.uuidString)_render.jpg"
        let thumbName = "\(id.uuidString)_thumb.jpg"
        try write(rendered, quality: 0.95, to: renderedName)
        try write(rendered.downscaled(toMaxDimension: 400), quality: 0.8, to: thumbName)
        return (renderedName, thumbName)
    }

    private func write(_ image: UIImage, quality: CGFloat, to fileName: String) throws {
        guard let data = image.jpegData(compressionQuality: quality) else {
            throw PhotoStorageError.encodingFailed
        }
        do {
            try data.write(to: url(for: fileName), options: .atomic)
        } catch {
            throw PhotoStorageError.writeFailed(fileName)
        }
    }

    // MARK: Read

    func load(_ fileName: String) -> UIImage? {
        UIImage(contentsOfFile: url(for: fileName).path)
    }

    // MARK: Delete

    func delete(_ photo: CapturedPhoto) {
        for name in [photo.originalFileName, photo.renderedFileName, photo.thumbnailFileName] {
            try? FileManager.default.removeItem(at: url(for: name))
        }
    }
}

// MARK: - Image scaling

extension UIImage {
    /// Returns a copy whose largest side is at most `maxDimension` px, preserving
    /// aspect ratio. Used for cheap gallery thumbnails.
    func downscaled(toMaxDimension maxDimension: CGFloat) -> UIImage {
        let longest = max(size.width, size.height)
        guard longest > maxDimension else { return self }
        let scale = maxDimension / longest
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
