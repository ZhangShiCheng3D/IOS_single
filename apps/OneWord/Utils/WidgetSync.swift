//
//  WidgetSync.swift
//  OneWord
//
//  Recomputes the shared widget snapshot from the current entries and asks
//  WidgetKit to refresh. Called whenever entries change.
//

import Foundation
import WidgetKit

enum WidgetSync {
    private static let insights = InsightsViewModel()

    static func update(entries: [DiaryEntry]) {
        let today = Date().startOfDay
        let snapshot = OneWordShared.Snapshot(
            streak: insights.currentStreak(from: entries),
            todayLogged: entries.contains { $0.date == today },
            total: entries.count
        )
        OneWordShared.save(snapshot)
        WidgetCenter.shared.reloadAllTimelines()
    }
}
