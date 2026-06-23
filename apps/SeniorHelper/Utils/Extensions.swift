//
//  Extensions.swift
//  SeniorHelper
//
//  通用扩展与辅助工具。
//

import SwiftUI
import UIKit

// MARK: - 沙盒文件存取

/// 负责把药盒照片读写到 Documents 目录，并提供轻量缓存。
enum ImageStore {

    private static var documentsURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    /// 保存图片，返回生成的文件名。失败返回 nil。
    static func save(_ image: UIImage) -> String? {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return nil }
        let fileName = "med_\(UUID().uuidString).jpg"
        let url = documentsURL.appendingPathComponent(fileName)
        do {
            try data.write(to: url, options: .atomic)
            return fileName
        } catch {
            print("保存图片失败: \(error.localizedDescription)")
            return nil
        }
    }

    /// 按文件名读取图片。
    static func load(_ fileName: String?) -> UIImage? {
        guard let fileName else { return nil }
        let url = documentsURL.appendingPathComponent(fileName)
        return UIImage(contentsOfFile: url.path)
    }

    /// 删除指定文件。
    static func delete(_ fileName: String?) {
        guard let fileName else { return }
        let url = documentsURL.appendingPathComponent(fileName)
        try? FileManager.default.removeItem(at: url)
    }
}

// MARK: - View 辅助

extension View {

    /// 统一的卡片容器样式：圆角表面 + 轻柔阴影，营造层次感。
    func cardStyle() -> some View {
        self
            .padding(Theme.padding)
            .background(
                RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                    .fill(Theme.cardBackground)
                    .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
            )
    }

    /// 条件修饰符：仅当条件为真时应用变换。
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition { transform(self) } else { self }
    }
}

// MARK: - 触觉反馈

enum Haptics {
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
    static func warning() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }
    static func tap() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
}
