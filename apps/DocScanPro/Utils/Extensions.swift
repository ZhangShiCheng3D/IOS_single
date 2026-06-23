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
    /// 友好的相对/绝对日期展示（用于文档列表）。
    var documentListDisplay: String {
        let formatter = DateFormatter()
        if Calendar.current.isDateInToday(self) {
            formatter.dateFormat = "HH:mm"
            return formatter.string(from: self)
        }
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: self)
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

// MARK: - View 条件修饰

extension View {
    /// 条件性地应用一个变换，便于链式书写。
    @ViewBuilder
    func applyIf<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
