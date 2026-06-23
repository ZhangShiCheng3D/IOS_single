//
//  FilmFilterEngine.swift
//  RetroFilm
//
//  The custom film-emulation pipeline. This is deliberately NOT a single
//  built-in CIFilter — it's a hand-built chain that stacks white balance,
//  a film tone curve (lifted shadows + rolled highlights), split toning,
//  matte fade, organic grain, vignette and optional light leaks, then an
//  optional burned-in date stamp.
//
//  All processing is GPU-accelerated through a single shared `CIContext`
//  and runs fully on-device. A small live (preview) path skips the most
//  expensive grain pass for smooth framerate; the export path renders the
//  full quality look.
//

import CoreImage
import CoreImage.CIFilterBuiltins
import UIKit

/// `@unchecked Sendable` is sound: `CIContext` is documented thread-safe for
/// rendering, and the only other stored state (`cachedNoise`) is immutable
/// after init. This lets the off-main capture processors share `.shared`.
final class FilmFilterEngine: @unchecked Sendable {

    /// One shared, Metal-backed context for the whole app. Creating CIContexts
    /// is expensive, so we never make them per-frame.
    static let shared = FilmFilterEngine()

    private let context: CIContext

    /// Cached random-noise tile so live preview doesn't regenerate it each frame.
    private let cachedNoise: CIImage = FilmFilterEngine.makeNoise()

    private init() {
        // Prefer Metal; fall back gracefully. Working in a wide-ish space keeps
        // the tone curve from clipping the saturated film highlights.
        let options: [CIContextOption: Any] = [
            .workingColorSpace: CGColorSpace(name: CGColorSpace.extendedLinearSRGB) as Any,
            .useSoftwareRenderer: false
        ]
        if let device = MTLCreateSystemDefaultDevice() {
            self.context = CIContext(mtlDevice: device, options: options)
        } else {
            self.context = CIContext(options: options)
        }
    }

    // MARK: - Public API

    /// Renders `input` with the given stock + settings and returns a `CGImage`.
    /// - Parameter quality: `.preview` is optimized for framerate (cheaper grain),
    ///   `.export` renders the full-resolution, full-quality look.
    func render(_ input: CIImage,
                stock: FilmStock,
                settings: FilterSettings,
                quality: Quality,
                date: Date = .now) -> CGImage? {
        let processed = pipeline(input, stock: stock, settings: settings, quality: quality, date: date)
        return context.createCGImage(processed, from: processed.extent)
    }

    /// Convenience: render a `UIImage` end-to-end (used by gallery / export).
    /// `date` is burned into the date stamp (when enabled) so a re-edit of an
    /// older photo stamps its *capture* date, not today.
    func renderUIImage(_ image: UIImage,
                       stock: FilmStock,
                       settings: FilterSettings,
                       quality: Quality = .export,
                       date: Date = .now) -> UIImage? {
        guard let ciInput = CIImage(image: image)?.oriented(forExifOrientation: image.exifOrientation) else {
            return nil
        }
        guard let cg = render(ciInput, stock: stock, settings: settings, quality: quality, date: date) else { return nil }
        return UIImage(cgImage: cg)
    }

    enum Quality { case preview, export }

    // MARK: - The chain

    /// Builds the full CIImage graph. Each stage is small and composable; the
    /// ordering matters (color → tone → toning → texture → optics → stamp).
    func pipeline(_ input: CIImage,
                  stock: FilmStock,
                  settings: FilterSettings,
                  quality: Quality,
                  date: Date = .now) -> CIImage {

        // "Original" with neutral settings → short-circuit (used by the wheel's
        // first slot and as the 0% intensity target).
        var image = input.clampedToExtent()
        let extent = input.extent

        // 1) Exposure (user) ----------------------------------------------------
        if settings.exposure != 0 {
            let f = CIFilter.exposureAdjust()
            f.inputImage = image
            f.ev = Float(settings.exposure * 1.5)
            image = f.outputImage ?? image
        }

        // 2) White balance: stock temp/tint + user warmth -----------------------
        let warmthOffset = settings.warmth * 1200.0
        let temp = CIFilter.temperatureAndTint()
        temp.inputImage = image
        temp.neutral = CIVector(x: CGFloat(6500 + stock.temperature + warmthOffset),
                                y: CGFloat(stock.tint))
        temp.targetNeutral = CIVector(x: 6500, y: 0)
        image = temp.outputImage ?? image

        // 3) Monochrome conversion (B&W stocks) ---------------------------------
        if stock.isMonochrome {
            let mono = CIFilter.colorControls()
            mono.inputImage = image
            mono.saturation = 0
            image = mono.outputImage ?? image
        }

        // 4) Color controls: saturation / contrast / brightness -----------------
        let cc = CIFilter.colorControls()
        cc.inputImage = image
        cc.saturation = Float(stock.isMonochrome ? 0 : stock.saturation)
        cc.contrast = Float(stock.contrast)
        cc.brightness = Float(stock.brightness)
        image = cc.outputImage ?? image

        // 5) Film tone curve: lift shadows, roll off highlights, matte fade -----
        image = applyToneCurve(image,
                               shadowLift: stock.shadowLift,
                               highlightRolloff: stock.highlightRolloff,
                               fade: stock.fade)

        // 6) Split toning: tint shadows & highlights differently (also gives
        //    B&W stocks an optional subtle warm/cool tone). -------------------
        if stock.toningStrength > 0 {
            image = applySplitToning(image, stock: stock)
        }

        // 7) Grain --------------------------------------------------------------
        let grainAmt = stock.grainAmount * settings.grain
        if grainAmt > 0.001 {
            image = applyGrain(image, amount: grainAmt, extent: extent, quality: quality)
        }

        // 8) Vignette -----------------------------------------------------------
        let vignetteAmt = stock.vignetteAmount * settings.vignette
        if vignetteAmt > 0.001 {
            let v = CIFilter.vignetteEffect()
            v.inputImage = image
            v.center = CIVector(x: extent.midX, y: extent.midY)
            v.radius = Float(max(extent.width, extent.height) * 0.62)
            v.intensity = Float(vignetteAmt * 1.1)
            v.falloff = 0.7
            image = v.outputImage ?? image
        }

        // 9) Light leak ---------------------------------------------------------
        let leakAmt = stock.lightLeakAmount * settings.lightLeak
        if leakAmt > 0.001 {
            image = applyLightLeak(image, amount: leakAmt, style: settings.lightLeakStyle, extent: extent)
        }

        // 10) Global intensity cross-fade with the untouched original -----------
        if settings.intensity < 0.999 {
            let blend = CIFilter.dissolveTransition()
            blend.inputImage = input.clampedToExtent()
            blend.targetImage = image
            blend.time = Float(settings.intensity)
            image = blend.outputImage ?? image
        }

        // Crop back to the original frame (clamp/grain extend to infinity).
        image = image.cropped(to: extent)

        // 11) Date stamp (burned in for export; also drawn in preview overlay) --
        if settings.dateStampEnabled {
            image = applyDateStamp(image, date: date, extent: extent)
        }

        return image
    }

    // MARK: - Stage helpers

    /// A custom RGB tone curve. Lifting the lowest point gives the milky film
    /// shadow; pulling the top point down compresses highlights. `fade` lifts
    /// the entire black point for a matte print look.
    private func applyToneCurve(_ image: CIImage,
                                shadowLift: Double,
                                highlightRolloff: Double,
                                fade: Double) -> CIImage {
        let curve = CIFilter.toneCurve()
        curve.inputImage = image

        let blackY = shadowLift * 0.18 + fade * 0.12
        let topY = 1.0 - highlightRolloff * 0.12

        curve.point0 = CGPoint(x: 0.00, y: blackY)
        curve.point1 = CGPoint(x: 0.25, y: 0.22 + shadowLift * 0.10)
        curve.point2 = CGPoint(x: 0.50, y: 0.50)
        curve.point3 = CGPoint(x: 0.75, y: 0.78 - highlightRolloff * 0.06)
        curve.point4 = CGPoint(x: 1.00, y: topY)
        return curve.outputImage ?? image
    }

    /// Split toning: build a luminance mask, tint shadows with `shadowTint` and
    /// highlights with `highlightTint`, composite back with `toningStrength`.
    private func applySplitToning(_ image: CIImage, stock: FilmStock) -> CIImage {
        let strength = CGFloat(stock.toningStrength)

        // Shadow tint: multiply-ish push into darks.
        let shadowColor = CIColor(red: CGFloat(stock.shadowTint.r),
                                  green: CGFloat(stock.shadowTint.g),
                                  blue: CGFloat(stock.shadowTint.b))
        let highColor = CIColor(red: CGFloat(stock.highlightTint.r),
                                green: CGFloat(stock.highlightTint.g),
                                blue: CGFloat(stock.highlightTint.b))

        // Highlight tint via a soft-light style screen using a constant color.
        let highImage = CIImage(color: highColor).cropped(to: image.extent)
        let screen = CIFilter.screenBlendMode()
        screen.backgroundImage = image
        screen.inputImage = multiplyAlpha(highImage, by: strength * 0.18)
        var toned = screen.outputImage ?? image

        // Shadow tint via multiply-ish darken push.
        let shadowImage = CIImage(color: CIColor(red: 1 - shadowColor.red * strength * 0.5,
                                                 green: 1 - shadowColor.green * strength * 0.5,
                                                 blue: 1 - shadowColor.blue * strength * 0.5))
            .cropped(to: image.extent)
        let multiply = CIFilter.multiplyBlendMode()
        multiply.backgroundImage = toned
        multiply.inputImage = shadowImage
        toned = multiply.outputImage ?? toned

        return toned
    }

    /// Organic monochrome-ish grain. We take random noise, desaturate it, scale
    /// its contrast by `amount`, and overlay-blend it. Live preview reuses a
    /// cached, lower-detail noise tile to keep framerate up.
    private func applyGrain(_ image: CIImage, amount: Double, extent: CGRect, quality: Quality) -> CIImage {
        let noiseSource = (quality == .preview) ? cachedNoise : Self.makeNoise()

        // Tile / crop noise to image size.
        let noise = noiseSource
            .cropped(to: extent.insetBy(dx: -10, dy: -10))
            .cropped(to: extent)

        // Desaturate noise → luminance grain, then center it around 0.5.
        let gray = CIFilter.colorControls()
        gray.inputImage = noise
        gray.saturation = 0
        gray.contrast = Float(0.5 + amount * 1.4)
        gray.brightness = 0
        guard let grayNoise = gray.outputImage else { return image }

        // Overlay blend keeps mid-tone exposure while adding texture.
        let overlay = CIFilter.overlayBlendMode()
        overlay.backgroundImage = image
        overlay.inputImage = multiplyAlpha(grayNoise, by: CGFloat(min(amount, 1.0)))
        return overlay.outputImage ?? image
    }

    /// Light leak: a warm radial/linear gradient flooded in from a corner,
    /// screen-blended so it only ever brightens. `style` rotates which corner.
    private func applyLightLeak(_ image: CIImage, amount: Double, style: Int, extent: CGRect) -> CIImage {
        let corners: [(CGFloat, CGFloat)] = [(0.05, 0.95), (0.95, 0.9), (0.1, 0.1), (0.9, 0.08)]
        let leakColors: [CIColor] = [
            CIColor(red: 1.0, green: 0.45, blue: 0.18),
            CIColor(red: 1.0, green: 0.30, blue: 0.30),
            CIColor(red: 1.0, green: 0.78, blue: 0.30),
            CIColor(red: 1.0, green: 0.55, blue: 0.20)
        ]
        let idx = ((style % corners.count) + corners.count) % corners.count
        let cx = extent.minX + extent.width * corners[idx].0
        let cy = extent.minY + extent.height * corners[idx].1

        let grad = CIFilter.radialGradient()
        grad.center = CIVector(x: cx, y: cy)
        grad.radius0 = 0
        grad.radius1 = Float(max(extent.width, extent.height) * 0.85)
        grad.color0 = leakColors[idx]
        grad.color1 = CIColor(red: 0, green: 0, blue: 0)
        guard let leak = grad.outputImage?.cropped(to: extent) else { return image }

        let screen = CIFilter.screenBlendMode()
        screen.backgroundImage = image
        screen.inputImage = multiplyAlpha(leak, by: CGFloat(amount * 0.7))
        return screen.outputImage ?? image
    }

    /// Burns a retro orange date stamp into the lower-right corner, the way a
    /// point-and-shoot's quartz-date back did.
    private func applyDateStamp(_ image: CIImage, date: Date, extent: CGRect) -> CIImage {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy'·'MM'·'dd"
        let text = formatter.string(from: date)

        let fontSize = max(extent.height * 0.035, 18)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont(name: "DBLCDTempBlack", size: fontSize)
                ?? UIFont.monospacedDigitSystemFont(ofSize: fontSize, weight: .bold),
            .foregroundColor: UIColor(red: 1.0, green: 0.55, blue: 0.15, alpha: 0.95)
        ]
        let attributed = NSAttributedString(string: text, attributes: attributes)
        let textSize = attributed.size()

        // Render the text to its own CGImage, then composite into the corner.
        let renderer = UIGraphicsImageRenderer(size: textSize)
        let stampImage = renderer.image { _ in
            attributed.draw(at: .zero)
        }
        guard let stampCI = CIImage(image: stampImage) else { return image }

        let margin = extent.width * 0.05
        let tx = extent.maxX - textSize.width - margin
        let ty = extent.minY + margin
        let positioned = stampCI.transformed(by: CGAffineTransform(translationX: tx, y: ty))

        let composite = CIFilter.sourceOverCompositing()
        composite.inputImage = positioned
        composite.backgroundImage = image
        return composite.outputImage ?? image
    }

    // MARK: - Primitives

    /// Scales an image's alpha by `factor` so it can be partially blended.
    private func multiplyAlpha(_ image: CIImage, by factor: CGFloat) -> CIImage {
        let matrix = CIFilter.colorMatrix()
        matrix.inputImage = image
        matrix.aVector = CIVector(x: 0, y: 0, z: 0, w: max(0, min(1, factor)))
        return matrix.outputImage ?? image
    }

    /// Generates a fresh tile of random noise.
    private static func makeNoise() -> CIImage {
        CIFilter.randomGenerator().outputImage ?? CIImage(color: CIColor(red: 0.5, green: 0.5, blue: 0.5))
    }
}

// MARK: - UIImage orientation helper

extension UIImage {
    /// Maps `UIImage.Orientation` to the EXIF orientation constant Core Image
    /// expects, so filtered output isn't rotated.
    var exifOrientation: Int32 {
        switch imageOrientation {
        case .up: return 1
        case .down: return 3
        case .left: return 8
        case .right: return 6
        case .upMirrored: return 2
        case .downMirrored: return 4
        case .leftMirrored: return 5
        case .rightMirrored: return 7
        @unknown default: return 1
        }
    }
}
