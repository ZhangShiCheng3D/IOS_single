//
//  CapturedPhoto.swift
//  RetroFilm
//
//  SwiftData model for a photo saved inside the app's own library.
//  The original (unfiltered) image and a JPEG render are stored on disk under
//  the app's Documents directory; SwiftData keeps the metadata + relative paths
//  so the store stays small and the library loads fast.
//

import Foundation
import SwiftData
import UIKit

@Model
final class CapturedPhoto {

    /// Stable unique id, also used to name files on disk.
    @Attribute(.unique) var id: UUID

    /// When the shot was taken.
    var createdAt: Date

    /// Identifier of the `FilmStock` applied at capture time.
    var filmStockID: String

    /// Encoded fine-tune settings so a photo can be re-edited later.
    var settingsData: Data

    /// Relative filename (under Documents) of the *original* full-res JPEG.
    var originalFileName: String

    /// Relative filename of the rendered (filtered) JPEG actually shown/exported.
    var renderedFileName: String

    /// Relative filename of a small thumbnail used in the gallery grid.
    var thumbnailFileName: String

    init(id: UUID = UUID(),
         createdAt: Date = .now,
         filmStockID: String,
         settings: FilterSettings,
         originalFileName: String,
         renderedFileName: String,
         thumbnailFileName: String) {
        self.id = id
        self.createdAt = createdAt
        self.filmStockID = filmStockID
        self.settingsData = (try? JSONEncoder().encode(settings)) ?? Data()
        self.originalFileName = originalFileName
        self.renderedFileName = renderedFileName
        self.thumbnailFileName = thumbnailFileName
    }

    /// Decoded fine-tune settings (falls back to defaults if data is corrupt).
    var settings: FilterSettings {
        (try? JSONDecoder().decode(FilterSettings.self, from: settingsData)) ?? .default
    }

    /// Convenience: resolved film stock.
    var filmStock: FilmStock { FilmStock.stock(for: filmStockID) }
}
