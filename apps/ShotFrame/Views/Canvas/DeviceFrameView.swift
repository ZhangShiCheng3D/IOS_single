//
//  DeviceFrameView.swift
//  ShotFrame
//
//  Pure-SwiftUI device mockups. Drawing the bezels with shapes (rather than
//  shipping PNG frame assets) keeps the bundle tiny and lets the frame scale to
//  any export resolution without blurring.
//

import SwiftUI

/// Wraps `content` (the screenshot) in a device shell. The `scale` argument is
/// the canvas's shorter side in points, so bezel thicknesses stay proportional
/// whether rendering a thumbnail or a 4K export.
struct DeviceFrameView<Content: View>: View {
    let frame: DeviceFrameType
    let scale: CGFloat
    let cornerRadius: CGFloat
    @ViewBuilder let content: Content

    var body: some View {
        switch frame {
        case .none:
            content
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        case .iPhone:
            phone
        case .iPad:
            pad
        case .macBook:
            mac
        case .browser:
            browser
        }
    }

    // MARK: iPhone — rounded shell with a dynamic-island pill

    private var phone: some View {
        let bezel = scale * 0.022
        let outerRadius = cornerRadius + bezel
        return content
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .padding(bezel)
            .background(
                RoundedRectangle(cornerRadius: outerRadius, style: .continuous)
                    .fill(Color(white: 0.08))
            )
            .overlay(alignment: .top) {
                Capsule()
                    .fill(Color.black)
                    .frame(width: scale * 0.16, height: bezel * 1.4)
                    .padding(.top, bezel * 1.5)
            }
            .overlay(
                RoundedRectangle(cornerRadius: outerRadius, style: .continuous)
                    .strokeBorder(Color(white: 0.28), lineWidth: bezel * 0.18)
            )
    }

    // MARK: iPad — thinner uniform bezel

    private var pad: some View {
        let bezel = scale * 0.018
        let outerRadius = cornerRadius + bezel
        return content
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .padding(bezel)
            .background(
                RoundedRectangle(cornerRadius: outerRadius, style: .continuous)
                    .fill(Color(white: 0.10))
            )
            .overlay(
                RoundedRectangle(cornerRadius: outerRadius, style: .continuous)
                    .strokeBorder(Color(white: 0.30), lineWidth: bezel * 0.15)
            )
    }

    // MARK: MacBook — screen + tapered base

    private var mac: some View {
        let bezel = scale * 0.012
        let screenRadius = scale * 0.02
        return VStack(spacing: 0) {
            content
                .clipShape(RoundedRectangle(cornerRadius: screenRadius, style: .continuous))
                .padding(bezel)
                .background(
                    RoundedRectangle(cornerRadius: screenRadius + bezel, style: .continuous)
                        .fill(Color(white: 0.08))
                )
            // Hinge / base
            ZStack {
                RoundedRectangle(cornerRadius: scale * 0.012, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(white: 0.62), Color(white: 0.42)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .frame(height: scale * 0.05)
                RoundedRectangle(cornerRadius: scale * 0.01, style: .continuous)
                    .fill(Color(white: 0.30))
                    .frame(width: scale * 0.14, height: scale * 0.02)
            }
            .padding(.horizontal, -scale * 0.06)
        }
    }

    // MARK: Browser — macOS-style window chrome with traffic lights

    private var browser: some View {
        let barHeight = scale * 0.06
        let radius = scale * 0.018
        return VStack(spacing: 0) {
            HStack(spacing: barHeight * 0.18) {
                Circle().fill(Color(hex: "FF5F57")).frame(width: barHeight * 0.22)
                Circle().fill(Color(hex: "FEBC2E")).frame(width: barHeight * 0.22)
                Circle().fill(Color(hex: "28C840")).frame(width: barHeight * 0.22)
                Spacer()
                Capsule()
                    .fill(Color(white: 0.85))
                    .frame(width: scale * 0.4, height: barHeight * 0.5)
                Spacer()
                Color.clear.frame(width: barHeight * 0.7)
            }
            .padding(.horizontal, barHeight * 0.4)
            .frame(height: barHeight)
            .background(Color(white: 0.95))

            content
        }
        .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .strokeBorder(Color(white: 0.80), lineWidth: scale * 0.002)
        )
    }
}

private extension Color {
    init(hex: String) { self = RGBAColor(hex: hex).color }
}

#Preview {
    VStack(spacing: 24) {
        DeviceFrameView(frame: .iPhone, scale: 300, cornerRadius: 28) {
            Color.blue.frame(width: 150, height: 320)
        }
        DeviceFrameView(frame: .browser, scale: 300, cornerRadius: 12) {
            Color.green.frame(width: 320, height: 200)
        }
    }
    .padding()
}
