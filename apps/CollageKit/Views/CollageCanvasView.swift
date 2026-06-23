//
//  CollageCanvasView.swift
//  CollageKit
//
//  实时拼图画布：所见即所得地呈现背景、插槽照片、文字叠加，
//  支持点选插槽、拖拽交换照片、拖动文字。与导出渲染共用 CollageLayout 几何。
//

import SwiftUI

struct CollageCanvasView: View {
    @Bindable var project: CollageProject
    @ObservedObject var viewModel: EditorViewModel
    /// 点击空插槽时回调（用于拉起相册选择）。
    var onTapEmptySlot: (Int) -> Void

    @State private var dragSlot: Int?
    @State private var dragTranslation: CGSize = .zero

    var body: some View {
        GeometryReader { geo in
            let canvas = canvasSize(in: geo.size)
            let factor = CollageLayout.scale(forCanvas: canvas)

            ZStack {
                backgroundLayer
                    .frame(width: canvas.width, height: canvas.height)

                ForEach(project.template.slots) { slot in
                    slotView(slot, canvas: canvas, factor: factor)
                }

                ForEach(project.texts) { text in
                    textView(text, canvas: canvas)
                }
            }
            .frame(width: canvas.width, height: canvas.height)
            .clipShape(RoundedRectangle(cornerRadius: 2))
            .overlay(
                RoundedRectangle(cornerRadius: 2)
                    .stroke(Color.black.opacity(0.06), lineWidth: 1)
            )
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .aspectRatio(project.aspectRatio.ratio, contentMode: .fit)
    }

    // MARK: - 背景

    @ViewBuilder
    private var backgroundLayer: some View {
        switch project.backgroundKind {
        case .solid:
            Color(hex: project.backgroundColorHex)
        case .gradient:
            LinearGradient(
                colors: [Color(hex: project.gradientStartHex),
                         Color(hex: project.gradientEndHex)],
                startPoint: gradientStart,
                endPoint: gradientEnd
            )
        }
    }

    private var gradientStart: UnitPoint {
        let a = project.gradientAngle * .pi / 180
        return UnitPoint(x: 0.5 - cos(a) / 2, y: 0.5 - sin(a) / 2)
    }
    private var gradientEnd: UnitPoint {
        let a = project.gradientAngle * .pi / 180
        return UnitPoint(x: 0.5 + cos(a) / 2, y: 0.5 + sin(a) / 2)
    }

    // MARK: - 插槽

    @ViewBuilder
    private func slotView(_ slot: TemplateSlot, canvas: CGSize, factor: CGFloat) -> some View {
        let frame = CollageLayout.frame(for: slot,
                                        canvasSize: canvas,
                                        border: CGFloat(project.borderWidth) * factor,
                                        spacing: CGFloat(project.spacing) * factor)
        let corner = CGFloat(project.cornerRadius) * factor
        let isSelected = viewModel.selectedSlotIndex == slot.id
        let image = viewModel.cachedImage(forSlot: slot.id, in: project)
        let isDragging = dragSlot == slot.id

        ZStack {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: frame.width, height: frame.height)
                    .scaleEffect(CGFloat(project.photo(forSlot: slot.id)?.scale ?? 1))
                    .offset(slotOffset(slot, frame: frame))
            } else {
                ZStack {
                    Color(.tertiarySystemFill)
                    Image(systemName: "plus")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                .frame(width: frame.width, height: frame.height)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .stroke(Color.accentColor, lineWidth: isSelected ? 3 : 0)
        )
        .opacity(isDragging ? 0.4 : 1)
        .frame(width: frame.width, height: frame.height)
        .position(x: frame.midX, y: frame.midY)
        .offset(isDragging ? dragTranslation : .zero)
        .zIndex(isDragging ? 10 : 0)
        .onTapGesture {
            viewModel.selectedTextID = nil
            if image == nil {
                onTapEmptySlot(slot.id)
            } else {
                viewModel.selectedSlotIndex = isSelected ? nil : slot.id
            }
        }
        .gesture(swapGesture(for: slot, canvas: canvas, factor: factor),
                 including: image != nil ? .all : .subviews)
    }

    private func slotOffset(_ slot: TemplateSlot, frame: CGRect) -> CGSize {
        guard let photo = project.photo(forSlot: slot.id) else { return .zero }
        return CGSize(width: photo.offsetX * frame.width,
                      height: photo.offsetY * frame.height)
    }

    /// 拖拽交换：把当前插槽拖到另一个插槽上即交换照片。
    private func swapGesture(for slot: TemplateSlot, canvas: CGSize, factor: CGFloat) -> some Gesture {
        LongPressGesture(minimumDuration: 0.25)
            .sequenced(before: DragGesture())
            .onChanged { value in
                switch value {
                case .second(true, let drag?):
                    dragSlot = slot.id
                    dragTranslation = drag.translation
                default:
                    break
                }
            }
            .onEnded { value in
                guard case .second(true, let drag?) = value else {
                    dragSlot = nil; dragTranslation = .zero; return
                }
                let origin = CollageLayout.frame(for: slot,
                                                 canvasSize: canvas,
                                                 border: CGFloat(project.borderWidth) * factor,
                                                 spacing: CGFloat(project.spacing) * factor)
                let dropPoint = CGPoint(x: origin.midX + drag.translation.width,
                                        y: origin.midY + drag.translation.height)
                if let target = self.slot(at: dropPoint, canvas: canvas, factor: factor),
                   target != slot.id {
                    withAnimation(.spring(duration: 0.3)) {
                        viewModel.swapSlots(slot.id, target, project: project)
                    }
                }
                dragSlot = nil
                dragTranslation = .zero
            }
    }

    private func slot(at point: CGPoint, canvas: CGSize, factor: CGFloat) -> Int? {
        for s in project.template.slots {
            let f = CollageLayout.frame(for: s,
                                        canvasSize: canvas,
                                        border: CGFloat(project.borderWidth) * factor,
                                        spacing: CGFloat(project.spacing) * factor)
            if f.contains(point) { return s.id }
        }
        return nil
    }

    // MARK: - 文字

    @ViewBuilder
    private func textView(_ text: CollageText, canvas: CGSize) -> some View {
        let isSelected = viewModel.selectedTextID == text.id
        let pointSize = CGFloat(text.fontSize) / 1000 * canvas.height

        Text(text.content)
            .font(.system(size: pointSize, weight: text.weight.fontWeight))
            .foregroundStyle(Color(hex: text.colorHex))
            .rotationEffect(.degrees(text.rotation))
            .padding(4)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.accentColor, style: StrokeStyle(lineWidth: isSelected ? 1.5 : 0, dash: [4]))
            )
            .position(x: text.normX * canvas.width, y: text.normY * canvas.height)
            .onTapGesture {
                viewModel.selectedSlotIndex = nil
                viewModel.selectedTextID = isSelected ? nil : text.id
            }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        viewModel.selectedTextID = text.id
                        text.normX = min(1, max(0, value.location.x / canvas.width))
                        text.normY = min(1, max(0, value.location.y / canvas.height))
                    }
                    .onEnded { _ in project.touch() }
            )
    }

    // MARK: - 几何

    private func canvasSize(in container: CGSize) -> CGSize {
        let ratio = project.aspectRatio.ratio
        if container.width / container.height > ratio {
            return CGSize(width: container.height * ratio, height: container.height)
        } else {
            return CGSize(width: container.width, height: container.width / ratio)
        }
    }
}
