//
//  AdjustmentPanel.swift
//  RetroFilm
//
//  The "滤镜参数微调" sheet. Sliders mutate a bound `FilterSettings`, so changes
//  reflect live in both the camera preview and the photo re-edit screen that
//  share this component.
//

import SwiftUI

struct AdjustmentPanel: View {
    @Binding var settings: FilterSettings
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    slider("adjust.intensity", value: $settings.intensity, range: 0...1, icon: "dial.medium")
                    slider("adjust.grain", value: $settings.grain, range: 0...2, icon: "circle.grid.3x3.fill")
                    slider("adjust.vignette", value: $settings.vignette, range: 0...2, icon: "circle.dashed")
                    slider("adjust.lightleak", value: $settings.lightLeak, range: 0...2, icon: "sun.max.fill")
                    slider("adjust.exposure", value: $settings.exposure, range: -1...1, icon: "plusminus")
                    slider("adjust.warmth", value: $settings.warmth, range: -1...1, icon: "thermometer.sun")

                    Stepper(value: $settings.lightLeakStyle, in: 0...3) {
                        Label("adjust.leakstyle", systemImage: "circles.hexagongrid")
                    }
                    .padding(.horizontal, 4)
                }
                .padding()
            }
            .navigationTitle("adjust.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("adjust.reset") { settings.resetAdjustments() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("action.done") { dismiss() }.bold()
                }
            }
        }
    }

    private func slider(_ titleKey: LocalizedStringKey,
                        value: Binding<Double>,
                        range: ClosedRange<Double>,
                        icon: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label(titleKey, systemImage: icon)
                    .font(.subheadline.weight(.medium))
                Spacer()
                Text(value.wrappedValue, format: .number.precision(.fractionLength(2)))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Slider(value: value, in: range)
                .tint(Theme.accent)
        }
    }
}

#Preview {
    AdjustmentPanel(settings: .constant(.default))
}
