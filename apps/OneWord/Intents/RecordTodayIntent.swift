//
//  RecordTodayIntent.swift
//  OneWord
//
//  Siri / Shortcuts entry point: "Add today's word". Opens the app and flags a
//  pending record so the app jumps straight into today's editor.
//

import AppIntents

struct RecordTodayIntent: AppIntent {
    static let title: LocalizedStringResource = "Record today's word"
    static let description = IntentDescription("Open OneWord and write today's one line.")

    /// Bring the app to the foreground; the app reads the pending flag and
    /// presents the editor.
    static let openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        OneWordShared.setPendingRecord()
        return .result()
    }
}

struct OneWordShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: RecordTodayIntent(),
            phrases: [
                "Record my word in \(.applicationName)",
                "Add today's word in \(.applicationName)",
                "Write in \(.applicationName)"
            ],
            shortTitle: "Record word",
            systemImageName: "square.and.pencil"
        )
    }
}
