//
//  PixelCanvasView.swift
//  PixelStudio
//
//  画布显示与触摸交互。使用 UIViewRepresentable 包裹自绘 UIView：
//  - 最近邻绘制合成图，保证像素硬边缘
//  - 透明区域绘制棋盘格
//  - 可选网格、镜像参考线、洋葱皮
//  - 触摸转像素坐标后驱动 EditorViewModel 的笔触
//

import SwiftUI
import UIKit

struct PixelCanvasView: UIViewRepresentable {
    @ObservedObject var vm: EditorViewModel

    func makeUIView(context: Context) -> PixelDrawingView {
        let view = PixelDrawingView()
        view.viewModel = vm
        view.backgroundColor = .clear
        view.isMultipleTouchEnabled = false
        return view
    }

    func updateUIView(_ uiView: PixelDrawingView, context: Context) {
        uiView.viewModel = vm
        uiView.syncFromViewModel()
    }
}

/// 真正负责绘制与触摸的 UIView。
final class PixelDrawingView: UIView {
    weak var viewModel: EditorViewModel?

    // 从 VM 同步过来的显示快照，避免在 draw 中访问 @Published 触发额外更新。
    private var displayImage: CGImage?
    private var onionImage: CGImage?
    private var showGrid = true
    private var mirror: MirrorMode = []
    private var pixelW = 1
    private var pixelH = 1

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentMode = .redraw
        isOpaque = false
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        contentMode = .redraw
        isOpaque = false
    }

    /// 从 VM 拉取最新显示状态并刷新。
    func syncFromViewModel() {
        guard let vm = viewModel else { return }
        displayImage = vm.displayImage
        onionImage = vm.onionImage
        showGrid = vm.showGrid
        mirror = vm.mirror
        pixelW = vm.width
        pixelH = vm.height
        setNeedsDisplay()
    }

    private var geometry: CanvasGeometry {
        CanvasGeometry(viewSize: bounds.size, pixelWidth: pixelW, pixelHeight: pixelH)
    }

    // MARK: - 绘制

    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        let g = geometry
        let imageRect = g.imageRect

        // 1. 棋盘格底（表示透明）
        drawCheckerboard(in: imageRect, context: ctx, cell: max(4, g.pixelSize))

        ctx.interpolationQuality = .none

        // 2. 洋葱皮（上一帧，半透明）
        if let onion = onionImage {
            ctx.saveGState()
            ctx.setAlpha(0.3)
            UIImage(cgImage: onion).draw(in: imageRect)
            ctx.restoreGState()
        }

        // 3. 当前合成图
        if let image = displayImage {
            UIImage(cgImage: image).draw(in: imageRect)
        }

        // 4. 网格
        if showGrid && g.pixelSize >= 6 {
            drawGrid(in: imageRect, context: ctx, geometry: g)
        }

        // 5. 镜像参考线
        drawMirrorGuides(in: imageRect, context: ctx)

        // 6. 画布外框
        ctx.setStrokeColor(UIColor.separator.cgColor)
        ctx.setLineWidth(1)
        ctx.stroke(imageRect.insetBy(dx: -0.5, dy: -0.5))
    }

    private func drawCheckerboard(in rect: CGRect, context ctx: CGContext, cell: CGFloat) {
        let light = UIColor(white: 0.92, alpha: 1).cgColor
        let dark = UIColor(white: 0.82, alpha: 1).cgColor
        ctx.saveGState()
        ctx.clip(to: rect)
        let cols = Int(ceil(rect.width / cell))
        let rows = Int(ceil(rect.height / cell))
        for row in 0...max(0, rows) {
            for col in 0...max(0, cols) {
                ctx.setFillColor((row + col) % 2 == 0 ? light : dark)
                ctx.fill(CGRect(x: rect.minX + CGFloat(col) * cell,
                                y: rect.minY + CGFloat(row) * cell,
                                width: cell, height: cell))
            }
        }
        ctx.restoreGState()
    }

    private func drawGrid(in rect: CGRect, context ctx: CGContext, geometry g: CanvasGeometry) {
        ctx.setStrokeColor(UIColor.label.withAlphaComponent(0.12).cgColor)
        ctx.setLineWidth(0.5)
        let step = g.pixelSize
        ctx.beginPath()
        for col in 0...pixelW {
            let x = rect.minX + CGFloat(col) * step
            ctx.move(to: CGPoint(x: x, y: rect.minY))
            ctx.addLine(to: CGPoint(x: x, y: rect.maxY))
        }
        for row in 0...pixelH {
            let y = rect.minY + CGFloat(row) * step
            ctx.move(to: CGPoint(x: rect.minX, y: y))
            ctx.addLine(to: CGPoint(x: rect.maxX, y: y))
        }
        ctx.strokePath()
    }

    private func drawMirrorGuides(in rect: CGRect, context ctx: CGContext) {
        ctx.setStrokeColor(UIColor.systemPink.withAlphaComponent(0.7).cgColor)
        ctx.setLineWidth(1)
        ctx.setLineDash(phase: 0, lengths: [4, 3])
        if mirror.contains(.horizontal) {
            let x = rect.midX
            ctx.move(to: CGPoint(x: x, y: rect.minY))
            ctx.addLine(to: CGPoint(x: x, y: rect.maxY))
        }
        if mirror.contains(.vertical) {
            let y = rect.midY
            ctx.move(to: CGPoint(x: rect.minX, y: y))
            ctx.addLine(to: CGPoint(x: rect.maxX, y: y))
        }
        ctx.strokePath()
        ctx.setLineDash(phase: 0, lengths: [])
    }

    // MARK: - 触摸

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, let vm = viewModel else { return }
        vm.beginStroke(at: touch.location(in: self), geometry: geometry)
        syncFromViewModel()
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, let vm = viewModel else { return }
        vm.continueStroke(to: touch.location(in: self), geometry: geometry)
        syncFromViewModel()
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, let vm = viewModel else { return }
        vm.endStroke(at: touch.location(in: self), geometry: geometry)
        syncFromViewModel()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, let vm = viewModel else { return }
        vm.endStroke(at: touch.location(in: self), geometry: geometry)
        syncFromViewModel()
    }
}

#Preview {
    let container = PreviewData.container
    let project = PreviewData.sampleProject(in: container)
    return PixelCanvasView(vm: EditorViewModel(project: project, context: container.mainContext))
        .frame(width: 320, height: 320)
        .padding()
}
