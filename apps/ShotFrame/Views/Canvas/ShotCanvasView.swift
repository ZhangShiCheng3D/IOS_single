//
//  ShotCanvasView.swift
//  ShotFrame
//
//  The single source of truth for what a composed shot looks like. The same view
//  drives the interactive editor preview AND the exported image (via
//  CanvasRenderer + ImageRenderer), guaranteeing WYSIWYG output.
//

import SwiftUI

struct ShotCanvasView: View {
    let image: UIImage?
    /// Optional user photo for `.image` backgrounds.
    let backgroundImage: UIImage?
    let settings: ShotSettings
    /// The exact point size at which to lay out the canvas. Both preview and
    /// export pass this explicitly so all fractional metrics resolve identically.
    let canvasSize: CGSize
    /// Whether the free watermark should be drawn (hidden for Pro users).
    var showWatermark: Bool = false

    /// Shorter side, the reference length for all proportional metrics.
    private var shortSide: CGFloat { min(canvasSize.width, canvasSize.height) }

    var body: some View {
        ZStack {
            background
            screenshotLayer
            annotationLayer
            if showWatermark { watermark }
        }
        .frame(width: canvasSize.width, height: canvasSize.height)
        .clipped()
    }

    // MARK: - Background

    @ViewBuilder
    private var background: some View {
        switch settings.background.kind {
        case .solid:
            settings.background.solidColor.color
        case .gradient:
            settings.background.gradient
        case .blurredImage:
            blurredBackground
        case .image:
            photoBackground
        }
    }

    @ViewBuilder
    private var blurredBackground: some View {
        if let image,
           let blurred = ImageProcessing.blurred(image, radius: settings.background.blurRadius) {
            Image(uiImage: blurred)
                .resizable()
                .scaledToFill()
                .frame(width: canvasSize.width, height: canvasSize.height)
                .overlay(Color.black.opacity(settings.background.overlayDarkness))
        } else {
            settings.background.gradient
        }
    }

    @ViewBuilder
    private var photoBackground: some View {
        if let backgroundImage {
            Image(uiImage: backgroundImage)
                .resizable()
                .scaledToFill()
                .frame(width: canvasSize.width, height: canvasSize.height)
                .overlay(Color.black.opacity(settings.background.overlayDarkness))
        } else {
            settings.background.gradient
        }
    }

    // MARK: - Screenshot

    @ViewBuilder
    private var screenshotLayer: some View {
        if let image {
            let padding = shortSide * settings.padding
            let available = CGSize(
                width: canvasSize.width - padding * 2,
                height: canvasSize.height - padding * 2
            )
            let target = fittedSize(for: image.aspectRatio, in: available)
            // Corner radius as a fraction of the rendered screenshot's short side.
            let radius = min(target.width, target.height) * settings.cornerRadius
            let shadowBlur = shortSide * settings.shadowRadius

            DeviceFrameView(frame: settings.deviceFrame, scale: shortSide, cornerRadius: radius) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: target.width, height: target.height)
            }
            .frame(width: target.width)
            .shadow(
                color: .black.opacity(settings.shadowOpacity),
                radius: shadowBlur,
                y: shadowBlur * 0.5
            )
        }
    }

    /// Largest size fitting `ratio` inside `bounds` (aspect-fit).
    private func fittedSize(for ratio: CGFloat, in bounds: CGSize) -> CGSize {
        guard bounds.width > 0, bounds.height > 0 else { return .zero }
        let boundsRatio = bounds.width / bounds.height
        if ratio > boundsRatio {
            return CGSize(width: bounds.width, height: bounds.width / ratio)
        } else {
            return CGSize(width: bounds.height * ratio, height: bounds.height)
        }
    }

    // MARK: - Annotations

    private var annotationLayer: some View {
        ForEach(settings.annotations) { annotation in
            Text(annotation.text)
                .font(.system(size: shortSide * annotation.fontScale, weight: annotation.isBold ? .bold : .regular, design: .rounded))
                .foregroundStyle(annotation.color.color)
                .shadow(
                    color: annotation.hasShadow ? .black.opacity(0.35) : .clear,
                    radius: annotation.hasShadow ? shortSide * 0.01 : 0,
                    y: annotation.hasShadow ? shortSide * 0.004 : 0
                )
                .multilineTextAlignment(.center)
                .frame(maxWidth: canvasSize.width * 0.9)
                .position(
                    x: annotation.position.x * canvasSize.width,
                    y: annotation.position.y * canvasSize.height
                )
        }
    }

    // MARK: - Watermark

    private var watermark: some View {
        VStack {
            Spacer()
            HStack(spacing: shortSide * 0.012) {
                Image(systemName: "wand.and.sparkles")
                Text("ShotFrame")
            }
            .font(.system(size: shortSide * 0.028, weight: .semibold, design: .rounded))
            .foregroundStyle(.white.opacity(0.9))
            .padding(.horizontal, shortSide * 0.03)
            .padding(.vertical, shortSide * 0.015)
            .background(.black.opacity(0.25), in: Capsule())
            .padding(.bottom, shortSide * 0.04)
        }
    }
}

#Preview {
    ShotCanvasView(
        image: UIImage(systemName: "photo")?.withRenderingMode(.alwaysTemplate),
        backgroundImage: nil,
        settings: TemplateLibrary.template(id: "sunset")!.settings,
        canvasSize: CGSize(width: 320, height: 400),
        showWatermark: true
    )
    .frame(width: 320, height: 400)
}
