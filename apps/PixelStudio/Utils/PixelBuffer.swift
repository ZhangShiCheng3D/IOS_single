//
//  PixelBuffer.swift
//  PixelStudio
//
//  画布的核心数据结构：一块连续的 RGBA8 像素缓冲区，提供所有底层绘制
//  原语（点、线、矩形、填充、镜像）。所有几何运算都在像素坐标系下进行，
//  与屏幕显示完全解耦。
//

import Foundation

/// 行优先、左上角为原点的 RGBA8 像素缓冲。
struct PixelBuffer: Equatable {
    let width: Int
    let height: Int
    /// 长度为 width * height * 4，顺序 R, G, B, A。
    private(set) var bytes: [UInt8]

    init(width: Int, height: Int) {
        self.width = width
        self.height = height
        self.bytes = [UInt8](repeating: 0, count: max(0, width * height * 4))
    }

    /// 从已有字节还原。尺寸不匹配时回退为空白缓冲，避免越界崩溃。
    init(width: Int, height: Int, bytes: [UInt8]) {
        self.width = width
        self.height = height
        if bytes.count == width * height * 4 {
            self.bytes = bytes
        } else {
            self.bytes = [UInt8](repeating: 0, count: max(0, width * height * 4))
        }
    }

    // MARK: - 像素读写

    @inline(__always)
    func contains(_ x: Int, _ y: Int) -> Bool {
        x >= 0 && y >= 0 && x < width && y < height
    }

    @inline(__always)
    func color(x: Int, y: Int) -> PixelColor {
        let i = (y * width + x) * 4
        return PixelColor(r: bytes[i], g: bytes[i + 1], b: bytes[i + 2], a: bytes[i + 3])
    }

    @inline(__always)
    mutating func setColor(_ c: PixelColor, x: Int, y: Int) {
        guard contains(x, y) else { return }
        let i = (y * width + x) * 4
        bytes[i] = c.r
        bytes[i + 1] = c.g
        bytes[i + 2] = c.b
        bytes[i + 3] = c.a
    }

    mutating func clear() {
        for i in bytes.indices { bytes[i] = 0 }
    }

    /// 用单色填满整块缓冲。
    mutating func fillAll(_ c: PixelColor) {
        var i = 0
        while i < bytes.count {
            bytes[i] = c.r
            bytes[i + 1] = c.g
            bytes[i + 2] = c.b
            bytes[i + 3] = c.a
            i += 4
        }
    }

    // MARK: - 绘制原语

    /// Bresenham 直线，保证拖动笔触不出现断点。
    mutating func drawLine(from p0: (Int, Int), to p1: (Int, Int), color: PixelColor) {
        var (x0, y0) = p0
        let (x1, y1) = p1
        let dx = abs(x1 - x0)
        let dy = -abs(y1 - y0)
        let sx = x0 < x1 ? 1 : -1
        let sy = y0 < y1 ? 1 : -1
        var err = dx + dy
        while true {
            setColor(color, x: x0, y: y0)
            if x0 == x1 && y0 == y1 { break }
            let e2 = 2 * err
            if e2 >= dy { err += dy; x0 += sx }
            if e2 <= dx { err += dx; y0 += sy }
        }
    }

    /// 矩形描边。
    mutating func drawRect(from p0: (Int, Int), to p1: (Int, Int), color: PixelColor) {
        let minX = min(p0.0, p1.0), maxX = max(p0.0, p1.0)
        let minY = min(p0.1, p1.1), maxY = max(p0.1, p1.1)
        for x in minX...maxX {
            setColor(color, x: x, y: minY)
            setColor(color, x: x, y: maxY)
        }
        for y in minY...maxY {
            setColor(color, x: minX, y: y)
            setColor(color, x: maxX, y: y)
        }
    }

    /// 实心矩形。
    mutating func fillRect(from p0: (Int, Int), to p1: (Int, Int), color: PixelColor) {
        let minX = min(p0.0, p1.0), maxX = max(p0.0, p1.0)
        let minY = min(p0.1, p1.1), maxY = max(p0.1, p1.1)
        for y in minY...maxY {
            for x in minX...maxX {
                setColor(color, x: x, y: y)
            }
        }
    }

    /// 4-连通泛洪填充。替换与起点同色的连通区域。
    mutating func floodFill(x: Int, y: Int, with color: PixelColor) {
        guard contains(x, y) else { return }
        let target = self.color(x: x, y: y)
        if target == color { return }

        var stack: [(Int, Int)] = [(x, y)]
        while let (cx, cy) = stack.popLast() {
            guard contains(cx, cy), self.color(x: cx, y: cy) == target else { continue }
            setColor(color, x: cx, y: cy)
            stack.append((cx + 1, cy))
            stack.append((cx - 1, cy))
            stack.append((cx, cy + 1))
            stack.append((cx, cy - 1))
        }
    }
}
