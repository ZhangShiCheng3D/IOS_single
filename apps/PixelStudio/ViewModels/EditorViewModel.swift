//
//  EditorViewModel.swift
//  PixelStudio
//
//  编辑器的核心状态机：持有内存文档、当前工具/颜色/图层，处理笔触生命周期、
//  撤销重做、图层与帧管理、合成显示图、以及向 SwiftData 持久化。
//

import SwiftUI
import SwiftData
import CoreGraphics

@MainActor
final class EditorViewModel: ObservableObject {

    // MARK: - 持久化引用
    private let project: PixelProject
    private let context: ModelContext

    let width: Int
    let height: Int

    // MARK: - 文档状态
    @Published private(set) var frames: [WorkingFrame]
    @Published var currentFrameIndex: Int = 0
    @Published var currentLayerIndex: Int = 0

    // MARK: - 工具状态
    @Published var tool: DrawingTool = .pencil
    @Published var currentColor: PixelColor
    @Published var palette: [PixelColor]
    @Published var brushSize: Int = 1
    @Published var mirror: MirrorMode = []
    @Published var showGrid: Bool = true
    @Published var showOnionSkin: Bool = false

    // MARK: - 显示输出
    @Published private(set) var displayImage: CGImage?
    @Published private(set) var onionImage: CGImage?

    // MARK: - 撤销 / 重做
    @Published private(set) var canUndo = false
    @Published private(set) var canRedo = false
    private var undoStack: [Snapshot] = []
    private var redoStack: [Snapshot] = []
    private let maxUndo = 60

    // MARK: - 付费墙
    @Published var pendingPaywallFeature: ProFeature?
    var isProUnlocked: Bool = false

    // MARK: - 笔触临时状态
    private var strokeActive = false
    private var strokeStart: (Int, Int) = (0, 0)
    private var lastPoint: (Int, Int) = (0, 0)
    /// 形状工具（直线/矩形）绘制时的预览缓冲，提交前不动真实图层。
    private var previewBuffer: PixelBuffer?

    private var autosaveTask: Task<Void, Never>?

    private struct Snapshot {
        var frames: [WorkingFrame]
        var frameIndex: Int
        var layerIndex: Int
    }

    // MARK: - 初始化

    init(project: PixelProject, context: ModelContext) {
        self.project = project
        self.context = context
        self.width = project.width
        self.height = project.height

        let loadedPalette = project.paletteHex.compactMap { PixelColor(hex: $0) }
        self.palette = loadedPalette.isEmpty ? DefaultPalette.lospec16.compactMap { PixelColor(hex: $0) } : loadedPalette
        self.currentColor = loadedPalette.first ?? .black

        // 载入帧/图层；保证至少一帧一层。
        var loaded: [WorkingFrame] = project.sortedFrames.map { f in
            let layers = f.sortedLayers.map { l in
                WorkingLayer(name: l.name,
                             isVisible: l.isVisible,
                             opacity: l.opacity,
                             buffer: l.buffer(width: project.width, height: project.height))
            }
            return WorkingFrame(duration: f.duration,
                                layers: layers.isEmpty
                                ? [WorkingLayer(name: "Layer 1", buffer: PixelBuffer(width: project.width, height: project.height))]
                                : layers)
        }
        if loaded.isEmpty {
            loaded = [WorkingFrame(layers: [WorkingLayer(name: "Layer 1",
                                                         buffer: PixelBuffer(width: project.width, height: project.height))])]
        }
        self.frames = loaded
        regenerateDisplay()
    }

    // MARK: - 便捷访问

    var currentFrame: WorkingFrame { frames[currentFrameIndex] }
    var currentLayer: WorkingLayer { frames[currentFrameIndex].layers[currentLayerIndex] }
    var frameCount: Int { frames.count }
    var layerCount: Int { frames[currentFrameIndex].layers.count }
    var projectName: String { project.name }

    private var activeBuffer: PixelBuffer {
        get { frames[currentFrameIndex].layers[currentLayerIndex].buffer }
        set { frames[currentFrameIndex].layers[currentLayerIndex].buffer = newValue }
    }

    // MARK: - 笔触生命周期

    func beginStroke(at point: CGPoint, geometry: CanvasGeometry) {
        let p = geometry.pixel(at: point)

        // 取色器：直接采样合成色，不修改画布。
        if tool == .eyedropper {
            sampleColor(at: p)
            return
        }
        guard currentLayer.isVisible else { return }

        pushUndo()
        strokeActive = true
        strokeStart = p
        lastPoint = p

        switch tool {
        case .pencil:
            stamp(into: &activeBuffer, x: p.x, y: p.y, color: currentColor)
        case .eraser:
            stamp(into: &activeBuffer, x: p.x, y: p.y, color: .clear)
        case .fill:
            applyFill(at: p)
            finishStroke()
        case .line, .rectangle:
            previewBuffer = activeBuffer
            drawShapePreview(to: p)
        case .eyedropper:
            break
        }
        regenerateDisplay()
    }

    func continueStroke(to point: CGPoint, geometry: CanvasGeometry) {
        guard strokeActive else { return }
        let p = geometry.pixel(at: point)

        switch tool {
        case .pencil:
            paintLine(into: &activeBuffer, from: lastPoint, to: p, color: currentColor)
            lastPoint = p
        case .eraser:
            paintLine(into: &activeBuffer, from: lastPoint, to: p, color: .clear)
            lastPoint = p
        case .line, .rectangle:
            drawShapePreview(to: p)
        default:
            break
        }
        regenerateDisplay()
    }

    func endStroke(at point: CGPoint, geometry: CanvasGeometry) {
        guard strokeActive else { return }
        let p = geometry.pixel(at: point)

        switch tool {
        case .line:
            paintLine(into: &activeBuffer, from: strokeStart, to: p, color: currentColor)
        case .rectangle:
            paintRect(into: &activeBuffer, from: strokeStart, to: p, color: currentColor)
        default:
            break
        }
        previewBuffer = nil
        finishStroke()
        regenerateDisplay()
    }

    private func finishStroke() {
        strokeActive = false
        scheduleAutosave()
    }

    // MARK: - 绘制辅助（镜像 + 笔刷）

    /// 根据镜像设置返回所有对称点（含原点）。
    private func mirroredPoints(_ x: Int, _ y: Int) -> [(Int, Int)] {
        var pts = [(x, y)]
        if mirror.contains(.horizontal) {
            pts += pts.map { (width - 1 - $0.0, $0.1) }
        }
        if mirror.contains(.vertical) {
            pts += pts.map { ($0.0, height - 1 - $0.1) }
        }
        return pts
    }

    /// 在某点落下一个 brushSize × brushSize 的方块，并对所有镜像点同步。
    private func stamp(into buffer: inout PixelBuffer, x: Int, y: Int, color: PixelColor) {
        let r = brushSize - 1
        for (mx, my) in mirroredPoints(x, y) {
            for dy in 0...r {
                for dx in 0...r {
                    buffer.setColor(color, x: mx + dx, y: my + dy)
                }
            }
        }
    }

    /// 沿 Bresenham 路径连续盖章，避免快速拖动出现断点。
    private func paintLine(into buffer: inout PixelBuffer, from p0: (Int, Int), to p1: (Int, Int), color: PixelColor) {
        var (x0, y0) = p0
        let (x1, y1) = p1
        let dx = abs(x1 - x0)
        let dy = -abs(y1 - y0)
        let sx = x0 < x1 ? 1 : -1
        let sy = y0 < y1 ? 1 : -1
        var err = dx + dy
        while true {
            stamp(into: &buffer, x: x0, y: y0, color: color)
            if x0 == x1 && y0 == y1 { break }
            let e2 = 2 * err
            if e2 >= dy { err += dy; x0 += sx }
            if e2 <= dx { err += dx; y0 += sy }
        }
    }

    /// 矩形描边（应用镜像）。
    private func paintRect(into buffer: inout PixelBuffer, from p0: (Int, Int), to p1: (Int, Int), color: PixelColor) {
        let minX = min(p0.0, p1.0), maxX = max(p0.0, p1.0)
        let minY = min(p0.1, p1.1), maxY = max(p0.1, p1.1)
        for x in minX...maxX {
            stamp(into: &buffer, x: x, y: minY, color: color)
            stamp(into: &buffer, x: x, y: maxY, color: color)
        }
        for y in minY...maxY {
            stamp(into: &buffer, x: minX, y: y, color: color)
            stamp(into: &buffer, x: maxX, y: y, color: color)
        }
    }

    private func applyFill(at p: (Int, Int)) {
        // 填充对每个镜像起点各做一次泛洪。
        for (mx, my) in mirroredPoints(p.x, p.y) {
            activeBuffer.floodFill(x: mx, y: my, with: currentColor)
        }
    }

    private func drawShapePreview(to p: (Int, Int)) {
        guard previewBuffer != nil else { return }
        previewBuffer = activeBuffer // 重置到提交前状态
        switch tool {
        case .line:
            paintLine(into: &previewBuffer!, from: strokeStart, to: p, color: currentColor)
        case .rectangle:
            paintRect(into: &previewBuffer!, from: strokeStart, to: p, color: currentColor)
        default:
            break
        }
    }

    private func sampleColor(at p: (Int, Int)) {
        guard activeBuffer.contains(p.x, p.y) else { return }
        // 自上而下找到第一个非透明像素。
        for layer in currentFrame.layers.reversed() where layer.isVisible {
            let c = layer.buffer.color(x: p.x, y: p.y)
            if !c.isTransparent {
                currentColor = PixelColor(r: c.r, g: c.g, b: c.b, a: 255)
                return
            }
        }
    }

    // MARK: - 显示合成

    func regenerateDisplay() {
        let frame = frames[currentFrameIndex]
        var inputs: [PixelRenderer.LayerInput] = []
        for (i, layer) in frame.layers.enumerated() {
            let buf = (i == currentLayerIndex && previewBuffer != nil) ? previewBuffer! : layer.buffer
            inputs.append(.init(buffer: buf, opacity: layer.opacity, isVisible: layer.isVisible))
        }
        displayImage = PixelRenderer.compositeImage(layers: inputs, width: width, height: height)
        regenerateOnion()
    }

    private func regenerateOnion() {
        guard showOnionSkin, currentFrameIndex > 0 else {
            onionImage = nil
            return
        }
        let prev = frames[currentFrameIndex - 1]
        let inputs = prev.layers.map {
            PixelRenderer.LayerInput(buffer: $0.buffer, opacity: $0.opacity, isVisible: $0.isVisible)
        }
        onionImage = PixelRenderer.compositeImage(layers: inputs, width: width, height: height)
    }

    /// 指定帧的合成图（供时间轴缩略图、动画播放、GIF 导出）。
    func image(forFrame index: Int) -> CGImage? {
        guard frames.indices.contains(index) else { return nil }
        let inputs = frames[index].layers.map {
            PixelRenderer.LayerInput(buffer: $0.buffer, opacity: $0.opacity, isVisible: $0.isVisible)
        }
        return PixelRenderer.compositeImage(layers: inputs, width: width, height: height)
    }

    // MARK: - 撤销 / 重做

    private func pushUndo() {
        undoStack.append(Snapshot(frames: frames, frameIndex: currentFrameIndex, layerIndex: currentLayerIndex))
        if undoStack.count > maxUndo { undoStack.removeFirst() }
        redoStack.removeAll()
        refreshUndoFlags()
    }

    func undo() {
        guard let snap = undoStack.popLast() else { return }
        redoStack.append(Snapshot(frames: frames, frameIndex: currentFrameIndex, layerIndex: currentLayerIndex))
        restore(snap)
    }

    func redo() {
        guard let snap = redoStack.popLast() else { return }
        undoStack.append(Snapshot(frames: frames, frameIndex: currentFrameIndex, layerIndex: currentLayerIndex))
        restore(snap)
    }

    private func restore(_ snap: Snapshot) {
        frames = snap.frames
        currentFrameIndex = min(snap.frameIndex, frames.count - 1)
        currentLayerIndex = min(snap.layerIndex, frames[currentFrameIndex].layers.count - 1)
        previewBuffer = nil
        refreshUndoFlags()
        regenerateDisplay()
        scheduleAutosave()
    }

    private func refreshUndoFlags() {
        canUndo = !undoStack.isEmpty
        canRedo = !redoStack.isEmpty
    }

    // MARK: - 图层管理

    func addLayer() {
        if !isProUnlocked && layerCount >= FreeLimits.maxLayers {
            AppHaptics.warning()
            pendingPaywallFeature = .extraLayers
            return
        }
        AppHaptics.impact(.light)
        pushUndo()
        let newBuffer = PixelBuffer(width: width, height: height)
        let name = String(format: NSLocalizedString("layer.named", comment: ""), layerCount + 1)
        frames[currentFrameIndex].layers.append(WorkingLayer(name: name, buffer: newBuffer))
        currentLayerIndex = layerCount - 1
        regenerateDisplay()
        scheduleAutosave()
    }

    func deleteLayer(at index: Int) {
        guard layerCount > 1, frames[currentFrameIndex].layers.indices.contains(index) else { return }
        pushUndo()
        frames[currentFrameIndex].layers.remove(at: index)
        currentLayerIndex = min(currentLayerIndex, layerCount - 1)
        regenerateDisplay()
        scheduleAutosave()
    }

    func toggleLayerVisibility(at index: Int) {
        guard frames[currentFrameIndex].layers.indices.contains(index) else { return }
        pushUndo()
        frames[currentFrameIndex].layers[index].isVisible.toggle()
        regenerateDisplay()
        scheduleAutosave()
    }

    func setLayerOpacity(_ opacity: Double, at index: Int) {
        guard frames[currentFrameIndex].layers.indices.contains(index) else { return }
        frames[currentFrameIndex].layers[index].opacity = opacity
        regenerateDisplay()
        scheduleAutosave()
    }

    func renameLayer(_ name: String, at index: Int) {
        guard frames[currentFrameIndex].layers.indices.contains(index) else { return }
        frames[currentFrameIndex].layers[index].name = name
        scheduleAutosave()
    }

    /// 上移/下移图层（改变叠放顺序）。
    func moveLayer(from: Int, to: Int) {
        guard frames[currentFrameIndex].layers.indices.contains(from),
              to >= 0, to < layerCount, from != to else { return }
        pushUndo()
        let layer = frames[currentFrameIndex].layers.remove(at: from)
        frames[currentFrameIndex].layers.insert(layer, at: to)
        currentLayerIndex = to
        regenerateDisplay()
        scheduleAutosave()
    }

    func clearActiveLayer() {
        pushUndo()
        frames[currentFrameIndex].layers[currentLayerIndex].buffer.clear()
        regenerateDisplay()
        scheduleAutosave()
    }

    // MARK: - 帧 / 动画管理

    /// 新增空白帧（复制当前帧的图层结构，内容为空）。
    func addFrame(duplicate: Bool) {
        if !isProUnlocked && frameCount >= FreeLimits.maxFrames {
            AppHaptics.warning()
            pendingPaywallFeature = .animation
            return
        }
        pushUndo()
        let source = frames[currentFrameIndex]
        let newLayers: [WorkingLayer]
        if duplicate {
            newLayers = source.layers.map {
                WorkingLayer(name: $0.name, isVisible: $0.isVisible, opacity: $0.opacity, buffer: $0.buffer)
            }
        } else {
            newLayers = source.layers.map {
                WorkingLayer(name: $0.name, isVisible: $0.isVisible, opacity: $0.opacity,
                             buffer: PixelBuffer(width: width, height: height))
            }
        }
        let newFrame = WorkingFrame(duration: source.duration, layers: newLayers)
        frames.insert(newFrame, at: currentFrameIndex + 1)
        currentFrameIndex += 1
        currentLayerIndex = min(currentLayerIndex, layerCount - 1)
        regenerateDisplay()
        scheduleAutosave()
    }

    func deleteFrame(at index: Int) {
        guard frameCount > 1, frames.indices.contains(index) else { return }
        pushUndo()
        frames.remove(at: index)
        currentFrameIndex = min(currentFrameIndex, frameCount - 1)
        currentLayerIndex = min(currentLayerIndex, layerCount - 1)
        regenerateDisplay()
        scheduleAutosave()
    }

    func selectFrame(_ index: Int) {
        guard frames.indices.contains(index) else { return }
        currentFrameIndex = index
        currentLayerIndex = min(currentLayerIndex, layerCount - 1)
        previewBuffer = nil
        regenerateDisplay()
    }

    func setFrameDuration(_ duration: Double, at index: Int) {
        guard frames.indices.contains(index) else { return }
        frames[index].duration = max(0.02, duration)
        scheduleAutosave()
    }

    // MARK: - 调色板

    func selectColor(_ color: PixelColor) {
        currentColor = color
    }

    func addCurrentColorToPalette() {
        guard !palette.contains(currentColor) else { return }
        palette.append(currentColor)
        scheduleAutosave()
    }

    func updatePaletteColor(_ color: PixelColor, at index: Int) {
        guard palette.indices.contains(index) else { return }
        palette[index] = color
        scheduleAutosave()
    }

    func removePaletteColor(at index: Int) {
        guard palette.indices.contains(index) else { return }
        palette.remove(at: index)
        scheduleAutosave()
    }

    // MARK: - 导出

    /// 当前帧 PNG。
    func exportCurrentFramePNG(scale: Int) throws -> Data {
        let inputs = currentFrame.layers.map {
            PixelRenderer.LayerInput(buffer: $0.buffer, opacity: $0.opacity, isVisible: $0.isVisible)
        }
        return try ImageExporter.pngData(from: activeBuffer, layers: inputs, scale: scale)
    }

    /// 全部帧合成的逐帧图与时长，用于 GIF。
    func exportGIF(scale: Int) throws -> Data {
        var images: [CGImage] = []
        var delays: [Double] = []
        for index in frames.indices {
            if let img = image(forFrame: index) {
                images.append(img)
                delays.append(frames[index].duration)
            }
        }
        return try ImageExporter.gifData(frames: images, delays: delays, scale: scale)
    }

    // MARK: - 持久化

    private func scheduleAutosave() {
        project.updatedAt = Date()
        autosaveTask?.cancel()
        autosaveTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            guard let self, !Task.isCancelled else { return }
            self.save()
        }
    }

    /// 立即把内存文档写回 SwiftData（重建帧/图层）。
    func save() {
        project.paletteHex = palette.map { $0.hexString }

        // 删除旧的帧（级联删除图层）。
        for f in project.frames { context.delete(f) }
        project.frames = []

        var rebuilt: [PixelFrame] = []
        for (fi, wf) in frames.enumerated() {
            let pf = PixelFrame(order: fi, duration: wf.duration)
            context.insert(pf)
            pf.project = project
            var newLayers: [PixelLayer] = []
            for (li, wl) in wf.layers.enumerated() {
                let pl = PixelLayer(order: li,
                                    name: wl.name,
                                    isVisible: wl.isVisible,
                                    opacity: wl.opacity,
                                    pixelData: Data(wl.buffer.bytes))
                context.insert(pl)
                pl.frame = pf
                newLayers.append(pl)
            }
            pf.layers = newLayers
            rebuilt.append(pf)
        }
        project.frames = rebuilt
        project.updatedAt = Date()
        try? context.save()
    }
}
