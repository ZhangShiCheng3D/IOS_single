//
//  CanvasRenderer.swift
//  ShotFrame
//
//  Turns a `ShotCanvasView` into a flat UIImage at an exact pixel size using
//  SwiftUI's `ImageRenderer` (Core Graphics backed). Because export and the
//  on-screen editor share the SAME `ShotCanvasView`, the saved file is a
//  pixel-faithful copy of the preview — true WYSIWYG.
//

import SwiftUI

/// Output quality presets, expressed as the canvas's longest edge in pixels.
enum ExportResolution: String, CaseIterable, Identifiable {
    case standard
    case high

    var id: String { rawValue }

    var longEdge: CGFloat {
        switch self {
        case .standard: return 2000
        case .high:     return 3200
        }
    }

    var titleKey: LocalizedStringKey {
        switch self {
        case .standard: return "export.res.standard"
        case .high:     return "export.res.high"
        }
    }
}

@MainActor
enum CanvasRenderer {

    /// Compute the canvas pixel size for a given source image and settings.
    static func canvasSize(for image: UIImage?, settings: ShotSettings, longEdge: CGFloat) -> CGSize {
        let ratio = settings.aspect.ratio ?? (image?.aspectRatio ?? 1)
        if ratio >= 1 {
            return CGSize(width: longEdge, height: (longEdge / ratio).rounded())
        } else {
            return CGSize(width: (longEdge * ratio).rounded(), height: longEdge)
        }
    }

    /// Render a finished image at a preset resolution.
    static func render(
        image: UIImage?,
        backgroundImage: UIImage?,
        settings: ShotSettings,
        resolution: ExportResolution,
        watermark: Bool
    ) -> UIImage? {
        render(image: image, backgroundImage: backgroundImage, settings: settings,
               longEdge: resolution.longEdge, watermark: watermark)
    }

    /// Render at an explicit longest-edge pixel size (used for thumbnails).
    /// Returns nil only if `ImageRenderer` fails.
    static func render(
        image: UIImage?,
        backgroundImage: UIImage?,
        settings: ShotSettings,
        longEdge: CGFloat,
        watermark: Bool
    ) -> UIImage? {
        let size = canvasSize(for: image, settings: settings, longEdge: longEdge)

        let canvas = ShotCanvasView(
            image: image,
            backgroundImage: backgroundImage,
            settings: settings,
            canvasSize: size,
            showWatermark: watermark
        )

        let renderer = ImageRenderer(content: canvas)
        // canvasSize is already expressed in target pixels, so render 1:1.
        renderer.scale = 1
        renderer.proposedSize = ProposedViewSize(size)
        renderer.isOpaque = true
        return renderer.uiImage
    }
}
