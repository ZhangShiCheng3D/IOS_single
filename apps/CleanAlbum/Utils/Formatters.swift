//
//  Formatters.swift
//  CleanAlbum
//
//  通用格式化工具。
//

import Foundation

enum ByteFormat {
    /// 把字节数格式化为人类可读的容量（如 "1.2 GB"）。
    static func string(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        formatter.allowedUnits = [.useMB, .useGB, .useKB]
        return formatter.string(fromByteCount: max(0, bytes))
    }
}

extension Int64 {
    var readableSize: String { ByteFormat.string(self) }
}
