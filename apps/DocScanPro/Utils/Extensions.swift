//
//  Extensions.swift
//  DocScanPro
//
//  通用扩展集合。
//

import SwiftUI
import UIKit

// MARK: - Color <-> Hex

extension Color {
    /// 从十六进制字符串构造颜色，支持 "#RRGGBB" 与 "RRGGBB"。
    init?(hex: String) {
        var hexString = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexString = hexString.replacingOccurrences(of: "#", with: "")

        guard hexString.count == 6,
              let value = UInt64(hexString, radix: 16) else {
            return nil
        }

        let r = Double((value & 0xFF0000) >> 16) / 255.0
        let g = Double((value & 0x00FF00) >> 8) / 255.0
        let b = Double(value & 0x0000FF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: 1.0)
    }
}

// MARK: - Date 格式化

extension Date {
    /// 复用 DateFormatter（初始化开销大），避免在列表逐行渲染时反复创建。
    private static let timeOnlyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    private static let mediumDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    /// 友好的相对/绝对日期展示（用于文档列表）。
    var documentListDisplay: String {
        if Calendar.current.isDateInToday(self) {
            return Date.timeOnlyFormatter.string(from: self)
        }
        return Date.mediumDateFormatter.string(from: self)
    }
}

// MARK: - UIImage 压缩

extension UIImage {
    /// 以指定质量编码为 JPEG，控制本地存储体积。
    func compressedJPEGData(quality: CGFloat = 0.8) -> Data? {
        jpegData(compressionQuality: quality)
    }
}

// MARK: - String

extension String {
    /// 去除首尾空白后是否为空。
    var isBlank: Bool {
        trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
