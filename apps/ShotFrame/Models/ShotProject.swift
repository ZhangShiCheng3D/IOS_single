//
//  ShotProject.swift
//  ShotFrame
//
//  SwiftData model for a saved project. The heavy image bytes are kept in
//  external storage; the editing recipe is a Codable value type.
//

import Foundation
import SwiftData
import UIKit

@Model
final class ShotProject {
    /// Stable identifier (also used for export file names).
    var id: UUID = UUID()
    var name: String = "Untitled"
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    /// The original imported screenshot (PNG/JPEG bytes).
    @Attribute(.externalStorage) var sourceImageData: Data?

    /// Optional custom background photo bytes (when background kind == .image).
    @Attribute(.externalStorage) var backgroundImageData: Data?

    /// The full editing recipe, persisted as a Codable struct.
    var settings: ShotSettings = ShotSettings.default

    init(
        name: String = "Untitled",
        sourceImageData: Data? = nil,
        settings: ShotSettings = .default
    ) {
        self.id = UUID()
        self.name = name
        self.createdAt = Date()
        self.updatedAt = Date()
        self.sourceImageData = sourceImageData
        self.settings = settings
    }

    /// Decoded source screenshot, if present.
    var sourceImage: UIImage? {
        guard let data = sourceImageData else { return nil }
        return UIImage(data: data)
    }

    /// Decoded background photo, if present.
    var backgroundImage: UIImage? {
        guard let data = backgroundImageData else { return nil }
        return UIImage(data: data)
    }

    /// Stamp the modification time. Call after any edit.
    func touch() {
        updatedAt = Date()
    }
}
