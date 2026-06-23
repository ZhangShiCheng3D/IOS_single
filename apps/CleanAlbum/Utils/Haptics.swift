//
//  Haptics.swift
//  CleanAlbum
//
//  轻量触觉反馈封装。集中管理，便于全 App 一致的手感。
//

import UIKit

/// 触觉反馈助手。所有调用都在主线程触发系统反馈生成器。
@MainActor
enum Haptics {

    /// 轻点：选择/取消选择照片等可逆操作。
    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }

    /// 轻量冲击：按下次要按钮、展开操作。
    static func light() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    /// 成功：清理完成、解锁成功。
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    /// 警告/失败：删除出错、购买失败。
    static func error() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }
}
