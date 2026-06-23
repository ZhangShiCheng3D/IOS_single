//
//  ImageProcessing.swift
//  ShotFrame
//
//  Core Image helpers for the genuinely pixel-level work: producing a blurred
//  background from the screenshot itself. The rest of the composition is done
//  with SwiftUI + ImageRenderer (see CanvasRenderer), which is itself backed by
//  Core Graphics.
//

import CoreImage
import CoreImage.CIFilterBuiltins
import UIKit

enum ImageProcessing {

    /// Shared GPU-backed context; reused to avoid per-call setup cost.
    private static let context = CIContext(options: [.useSoftwareRenderer: false])

    /// Produce a blurred, slightly enlarged version of `image` suitable for use
    /// as a full-bleed background. The clamp filter prevents transparent edges
    /// that a plain Gaussian blur would create.
    static func blurred(_ image: UIImage, radius: Double) -> UIImage? {
        guard let ciImage = CIImage(image: image) else { return nil }

        let clamp = CIFilter.affineClamp()
        clamp.inputImage = ciImage
        clamp.transform = CGAffineTransform.identity

        let blur = CIFilter.gaussianBlur()
        blur.inputImage = clamp.outputImage
        blur.radius = Float(radius)

        guard
            let output = blur.outputImage,
            // Crop back to the original extent after the clamp's infinite extent.
            let cgImage = context.createCGImage(output, from: ciImage.extent)
        else { return nil }

        return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
    }

    /// Average color of an image, used to derive a tasteful auto background.
    static func averageColor(of image: UIImage) -> RGBAColor? {
        guard let ciImage = CIImage(image: image) else { return nil }
        let extent = ciImage.extent
        let filter = CIFilter.areaAverage()
        filter.inputImage = ciImage
        filter.extent = extent
        guard let output = filter.outputImage else { return nil }

        var bitmap = [UInt8](repeating: 0, count: 4)
        context.render(
            output,
            toBitmap: &bitmap,
            rowBytes: 4,
            bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
            format: .RGBA8,
            colorSpace: CGColorSpaceCreateDeviceRGB()
        )
        return RGBAColor(
            red: Double(bitmap[0]) / 255,
            green: Double(bitmap[1]) / 255,
            blue: Double(bitmap[2]) / 255,
            opacity: 1
        )
    }
}
