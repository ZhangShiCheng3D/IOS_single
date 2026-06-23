//
//  PhotoGroup.swift
//  CleanAlbum
//
//  一组重复 / 相似 / 模糊照片的集合。
//

import Foundation

/// 照片分组类型。
enum PhotoGroupKind: String, CaseIterable, Identifiable {
    case duplicate   // 几乎完全相同
    case similar     // 相似（如连拍）
    case blurry      // 模糊

    var id: String { rawValue }

    var titleKey: String {
        switch self {
        case .duplicate: return "group.duplicate"
        case .similar:   return "group.similar"
        case .blurry:    return "group.blurry"
        }
    }

    var systemImage: String {
        switch self {
        case .duplicate: return "doc.on.doc.fill"
        case .similar:   return "square.stack.3d.up.fill"
        case .blurry:    return "camera.metering.spot"
        }
    }
}

/// 一个可清理的照片分组。
///
/// `@unchecked Sendable`：由 `PhotoAnalyzer` actor 构造后交给 MainActor 使用，
/// 构造完成前不被外部访问，无并发写入。
@Observable
final class PhotoGroup: Identifiable, @unchecked Sendable {

    let id = UUID()
    let kind: PhotoGroupKind

    /// 组内照片。第 0 张默认视为"建议保留"的最佳照片。
    var items: [PhotoItem]

    init(kind: PhotoGroupKind, items: [PhotoItem]) {
        self.kind = kind
        self.items = items
    }

    /// 组内被选中（待删除）的照片。
    var selectedItems: [PhotoItem] { items.filter(\.isSelected) }

    /// 选中照片可释放的总字节数。
    var reclaimableBytes: Int64 { selectedItems.reduce(0) { $0 + $1.byteSize } }

    /// 建议保留的照片（清晰度最高，其次像素最大）。
    var suggestedKeeper: PhotoItem? {
        items.max { a, b in
            let sa = a.sharpnessScore ?? 0
            let sb = b.sharpnessScore ?? 0
            if sa == sb { return a.byteSize < b.byteSize }
            return sa < sb
        }
    }

    /// 默认选择策略：保留最佳，其余选中待删。
    func applyDefaultSelection() {
        guard let keeper = suggestedKeeper else { return }
        for item in items {
            item.isSelected = (item.id != keeper.id)
        }
    }
}
