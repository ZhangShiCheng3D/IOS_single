//
//  WidgetShared.swift
//  OneWord  (compiled into BOTH the app and the widget extension)
//
//  A tiny snapshot the app writes to a shared App Group container so the
//  widget can render the streak and today's status without touching SwiftData.
//  Stays on-device: an App Group is local storage, not a network service.
//

import Foundation

enum OneWordShared {
    /// App Group shared by the app and widget extension.
    static let appGroup = "group.com.oneword.shared"
    /// Deep link the widget opens to jump straight into today's editor.
    static let recordURL = URL(string: "oneword://record")!

    /// Minimal data the widget needs.
    struct Snapshot: Codable {
        var streak: Int = 0
        var todayLogged: Bool = false
        var total: Int = 0
    }

    private static let key = "snapshot"
    private static var store: UserDefaults? { UserDefaults(suiteName: appGroup) }

    static func save(_ snapshot: Snapshot) {
        guard let store, let data = try? JSONEncoder().encode(snapshot) else { return }
        store.set(data, forKey: key)
    }

    static func load() -> Snapshot {
        guard let store,
              let data = store.data(forKey: key),
              let snapshot = try? JSONDecoder().decode(Snapshot.self, from: data)
        else { return Snapshot() }
        return snapshot
    }

    // MARK: - Pending record (set by the Siri/Shortcuts intent)

    private static let pendingKey = "pendingRecord"
    static func setPendingRecord() { store?.set(true, forKey: pendingKey) }
    static func consumePendingRecord() -> Bool {
        guard let store, store.bool(forKey: pendingKey) else { return false }
        store.set(false, forKey: pendingKey)
        return true
    }
}
