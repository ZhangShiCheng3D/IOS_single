//
//  EditorPanels.swift
//  ShotFrame
//
//  The five control panels shown beneath the canvas (Template, Background,
//  Frame, Adjust, Text) plus the small reusable controls they share. Every
//  panel mutates `EditorViewModel.settings`, which drives the live preview.
//

import SwiftUI
import SwiftData
import PhotosUI

// MARK: - Shared controls

/// A labeled slider row used throughout the adjustment panels.
struct SliderRow: View {
    let titleKey: LocalizedStringKey
    @Binding var value: Double
    var range: ClosedRange<Double>

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(titleKey).font(.subheadline)
                Spacer()
                Text("\(Int((value - range.lowerBound) / (range.upperBound - range.lowerBound) * 100))%")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Slider(value: $value, in: range)
        }
    }
}

/// A small crown badge marking Pro-only items.
struct ProLockBadge: View {
    var body: some View {
        Image(systemName: "crown.fill")
            .font(.caption2.weight(.bold))
            .foregroundStyle(.white)
            .padding(5)
            .background(.orange, in: Circle())
            .shadow(color: .black.opacity(0.2), radius: 2, y: 1)
    }
}

/// A selectable icon + label chip (frames, aspects, kinds).
struct ToolChip: View {
    let titleKey: LocalizedStringKey
    let systemImage: String
    let isSelected: Bool
    var isLocked: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.title3)
                Text(titleKey)
                    .font(.caption2)
                    .lineLimit(1)
            }
            .frame(width: 76, height: 64)
            .foregroundStyle(isSelected ? .white : .primary)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isSelected ? AnyShapeStyle(Color("AccentColor").gradient) : AnyShapeStyle(Color(.secondarySystemBackground)))
            )
            .overlay(alignment: .topTrailing) {
                if isLocked { ProLockBadge().offset(x: 4, y: -4) }
            }
        }
        .buttonStyle(.plain)
    }
}

private struct PanelHeader: View {
    let titleKey: LocalizedStringKey
    var body: some View {
        Text(titleKey)
            .font(.footnote.weight(.semibold))
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Template panel

struct TemplatePanel: View {
    @ObservedObject var vm: EditorViewModel
    @EnvironmentObject private var purchases: PurchaseManager
    let requestPro: () -> Void

    private let columns = [GridItem(.adaptive(minimum: 96), spacing: 12)]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            PanelHeader(titleKey: "tool.template")
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(TemplateLibrary.all) { template in
                    Button {
                        if !vm.apply(template: template, isPro: purchases.isPro) {
                            requestPro()
                        }
                    } label: {
                        templateSwatch(template)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
    }

    private func templateSwatch(_ template: ShotTemplate) -> some View {
        VStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: template.swatch.map(\.color),
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
                .frame(height: 76)
                .overlay(alignment: .topTrailing) {
                    if template.isPro && !purchases.isPro {
                        ProLockBadge().padding(6)
                    }
                }
                .overlay {
                    Image(systemName: template.settings.deviceFrame.systemImage)
                        .font(.title3)
                        .foregroundStyle(.white.opacity(0.85))
                }
            Text(template.name)
                .font(.caption2)
                .lineLimit(1)
        }
    }
}

// MARK: - Background panel

/// Local gradient presets offered in the background panel.
private struct GradientPreset: Identifiable {
    let id = UUID()
    let hexes: [String]
    let angle: Double
}

struct BackgroundPanel: View {
    @ObservedObject var vm: EditorViewModel
    @EnvironmentObject private var purchases: PurchaseManager
    let requestPro: () -> Void

    @State private var bgItem: PhotosPickerItem?

    private let solids = ["0B1020", "1C1C1E", "FFFFFF", "F2F2F7", "FF6B6B", "FFA94D",
                          "FFD43B", "51CF66", "22B8CF", "4DABF7", "5C7CFA", "9775FA",
                          "F06595", "E64980", "212529", "495057"]

    private let gradients: [GradientPreset] = [
        .init(hexes: ["7F7FD5", "86A8E7", "91EAE4"], angle: 135),
        .init(hexes: ["FF9A9E", "FAD0C4"], angle: 120),
        .init(hexes: ["A18CD1", "FBC2EB"], angle: 115),
        .init(hexes: ["FAD961", "F76B1C"], angle: 140),
        .init(hexes: ["43E97B", "38F9D7"], angle: 130),
        .init(hexes: ["4FACFE", "00F2FE"], angle: 125),
        .init(hexes: ["667EEA", "764BA2"], angle: 145),
        .init(hexes: ["0F2027", "203A43", "2C5364"], angle: 150),
        .init(hexes: ["FC466B", "3F5EFB"], angle: 135),
        .init(hexes: ["232526", "414345"], angle: 160)
    ]

    private let columns = [GridItem(.adaptive(minimum: 54), spacing: 10)]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            kindPicker

            switch vm.settings.background.kind {
            case .solid:    solidSection
            case .gradient: gradientSection
            case .blurredImage: blurSection
            case .image:    imageSection
            }
        }
        .padding(16)
        .onChange(of: bgItem) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    vm.setBackgroundImage(image.downscaled(maxDimension: 2000))
                }
                bgItem = nil
            }
        }
    }

    private var kindPicker: some View {
        Picker("tool.background", selection: $vm.settings.background.kind) {
            ForEach(BackgroundKind.allCases) { kind in
                Text(kind.displayName).tag(kind)
            }
        }
        .pickerStyle(.segmented)
    }

    private var solidSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(Array(solids.enumerated()), id: \.element) { index, hex in
                    Button {
                        vm.settings.background.solidColor = RGBAColor(hex: hex)
                        Haptics.selection()
                    } label: {
                        Circle()
                            .fill(RGBAColor(hex: hex).color)
                            .frame(width: 44, height: 44)
                            .overlay(Circle().strokeBorder(.white.opacity(0.6), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text("a11y.color.swatch \(index + 1)"))
                }
            }
            ColorPicker("background.custom", selection: solidBinding, supportsOpacity: false)
        }
    }

    private var gradientSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 70), spacing: 10)], spacing: 10) {
                ForEach(Array(gradients.enumerated()), id: \.element.id) { index, preset in
                    Button {
                        vm.settings.background.gradientColors = preset.hexes.map { RGBAColor(hex: $0) }
                        vm.settings.background.gradientAngle = preset.angle
                        Haptics.selection()
                    } label: {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(LinearGradient(colors: preset.hexes.map { RGBAColor(hex: $0).color },
                                                 startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(height: 48)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text("a11y.gradient.swatch \(index + 1)"))
                }
            }
            SliderRow(titleKey: "background.angle", value: $vm.settings.background.gradientAngle, range: 0...360)
            HStack(spacing: 16) {
                ColorPicker("background.start", selection: gradientStopBinding(0), supportsOpacity: false)
                ColorPicker("background.end", selection: gradientStopBinding(1), supportsOpacity: false)
            }
        }
    }

    private var blurSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("background.blur.hint")
                .font(.footnote).foregroundStyle(.secondary)
            SliderRow(titleKey: "background.blur", value: $vm.settings.background.blurRadius, range: 5...80)
            SliderRow(titleKey: "background.dim", value: $vm.settings.background.overlayDarkness, range: 0...0.6)
        }
    }

    private var imageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            PhotosPicker(selection: $bgItem, matching: .images) {
                Label("background.choose", systemImage: "photo")
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            SliderRow(titleKey: "background.dim", value: $vm.settings.background.overlayDarkness, range: 0...0.6)
        }
    }

    // Bindings bridging RGBAColor <-> Color.
    private var solidBinding: Binding<Color> {
        Binding(get: { vm.settings.background.solidColor.color },
                set: { vm.settings.background.solidColor = RGBAColor($0) })
    }

    private func gradientStopBinding(_ index: Int) -> Binding<Color> {
        Binding(
            get: {
                let colors = vm.settings.background.gradientColors
                return index < colors.count ? colors[index].color : .white
            },
            set: { newValue in
                var colors = vm.settings.background.gradientColors
                while colors.count <= index { colors.append(.white) }
                colors[index] = RGBAColor(newValue)
                vm.settings.background.gradientColors = colors
            }
        )
    }
}

// MARK: - Frame panel

struct FramePanel: View {
    @ObservedObject var vm: EditorViewModel
    @EnvironmentObject private var purchases: PurchaseManager
    let requestPro: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            PanelHeader(titleKey: "tool.frame")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(DeviceFrameType.allCases) { frame in
                        ToolChip(
                            titleKey: frame.displayName,
                            systemImage: frame.systemImage,
                            isSelected: vm.settings.deviceFrame == frame,
                            isLocked: frame.isPro && !purchases.isPro
                        ) {
                            if frame.isPro && !purchases.isPro {
                                requestPro()
                            } else {
                                vm.settings.deviceFrame = frame
                                Haptics.selection()
                            }
                        }
                    }
                }
            }
        }
        .padding(16)
    }
}

// MARK: - Adjust panel

struct AdjustPanel: View {
    @ObservedObject var vm: EditorViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            PanelHeader(titleKey: "adjust.aspect")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(CanvasAspect.allCases) { aspect in
                        ToolChip(
                            titleKey: aspect.displayName,
                            systemImage: aspect.systemImage,
                            isSelected: vm.settings.aspect == aspect
                        ) {
                            vm.settings.aspect = aspect
                            Haptics.selection()
                        }
                    }
                }
            }

            SliderRow(titleKey: "adjust.padding", value: $vm.settings.padding, range: 0...0.30)
            SliderRow(titleKey: "adjust.corner", value: $vm.settings.cornerRadius, range: 0...0.12)
            SliderRow(titleKey: "adjust.shadow", value: $vm.settings.shadowRadius, range: 0...0.10)
            SliderRow(titleKey: "adjust.shadowOpacity", value: $vm.settings.shadowOpacity, range: 0...0.80)
        }
        .padding(16)
    }
}

// MARK: - Text panel

struct TextPanel: View {
    @ObservedObject var vm: EditorViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Button {
                    vm.addAnnotation()
                } label: {
                    Label("text.add", systemImage: "plus.circle.fill")
                }
                Spacer()
                if vm.selectedAnnotationID != nil {
                    Button(role: .destructive) {
                        vm.removeSelectedAnnotation()
                    } label: {
                        Label("text.remove", systemImage: "trash")
                    }
                }
            }
            .font(.subheadline.weight(.medium))

            if vm.settings.annotations.isEmpty {
                Text("text.empty")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                annotationChips
            }

            if let binding = vm.selectedAnnotation {
                editor(for: binding)
            }
        }
        .padding(16)
    }

    private var annotationChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(vm.settings.annotations) { annotation in
                    Text(annotation.text.isEmpty ? " " : annotation.text)
                        .font(.caption)
                        .lineLimit(1)
                        .padding(.horizontal, 12).padding(.vertical, 8)
                        .background(
                            Capsule().fill(vm.selectedAnnotationID == annotation.id
                                           ? AnyShapeStyle(Color("AccentColor").opacity(0.2))
                                           : AnyShapeStyle(Color(.secondarySystemBackground)))
                        )
                        .overlay(
                            Capsule().strokeBorder(
                                vm.selectedAnnotationID == annotation.id ? Color("AccentColor") : .clear,
                                lineWidth: 1.5)
                        )
                        .onTapGesture { vm.selectedAnnotationID = annotation.id }
                }
            }
        }
    }

    @ViewBuilder
    private func editor(for binding: Binding<Annotation>) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("text.placeholder", text: binding.text, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(1...3)

            HStack {
                Toggle("text.bold", isOn: binding.isBold)
                    .toggleStyle(.button)
                Toggle("text.shadow", isOn: binding.hasShadow)
                    .toggleStyle(.button)
                Spacer()
                ColorPicker("", selection: Binding(
                    get: { binding.wrappedValue.color.color },
                    set: { binding.wrappedValue.color = RGBAColor($0) }
                ), supportsOpacity: false)
                .labelsHidden()
            }
            .font(.subheadline)

            SliderRow(titleKey: "text.size", value: binding.fontScale, range: 0.02...0.14)

            Text("text.drag.hint")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 4)
    }
}

#Preview("Adjust") {
    let container = try! ModelContainer(for: ShotProject.self,
                                        configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let project = ShotProject(name: "Demo", sourceImageData: Data())
    return AdjustPanel(vm: EditorViewModel(project: project, context: container.mainContext))
        .environmentObject(PurchaseManager())
}
