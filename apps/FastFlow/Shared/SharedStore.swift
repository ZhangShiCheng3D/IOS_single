//
//  SharedStore.swift
//  FastFlow
//
//  主 App 与 Widget Extension 之间的轻量共享存储（App Group UserDefaults）。
//  仅存放 Widget 展示所需的当前断食快照。
//  ⚠️ 此文件需同时加入「主 App」与「Widget Extension」两个 Target，
//     并在两者的 Capabilities 中启用相同的 App Group。
//

import Foundation
import WidgetKit

/// 供 Widget 渲染的当前断食快照。
struct FastingSnapshot: Codable {
    var isFasting: Bool
    var startTime: Date
    var targetEndTime: Date
    var planName: String

    /// 空闲态占位快照。
    static let idle = FastingSnapshot(
        isFasting: false,
        startTime: .now,
        targetEndTime: .now,
        planName: "—"
    )
}

/// 共享存储读写入口。
enum SharedStore {
    /// App Group 标识，需与 entitlements 配置一致。
    static let appGroupID = "group.com.fastflow.shared"
    private static let snapshotKey = "fastflow.snapshot"

    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }

    /// 写入快照并刷新所有 Widget 时间线。
    static func save(_ snapshot: FastingSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults?.set(data, forKey: snapshotKey)
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// 读取快照，缺失时返回空闲态。
    static func load() -> FastingSnapshot {
        guard let data = defaults?.data(forKey: snapshotKey),
              let snapshot = try? JSONDecoder().decode(FastingSnapshot.self, from: data)
        else { return .idle }
        return snapshot
    }
}
