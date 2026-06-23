//
//  OneWordApp.swift
//  OneWord
//
//  App entry point. Configures the SwiftData model container and injects
//  the shared managers (purchase + app lock) into the environment.
//

import SwiftUI
import SwiftData

@main
struct OneWordApp: App {

    /// Shared StoreKit 2 purchase manager (owns transaction listening).
    @State private var purchaseManager = PurchaseManager()

    /// Drives the biometric / passcode privacy lock.
    @State private var appLock = AppLock()

    /// Owns the optional daily on-device reminder.
    @State private var notifications = NotificationManager()

    /// Optional opt-in mirroring of moods into Apple Health (State of Mind).
    @State private var health = HealthManager()

    /// The SwiftData container holding all diary entries. Stored locally only.
    let modelContainer: ModelContainer

    @MainActor
    init() {
        do {
            let schema = Schema([DiaryEntry.self])
            // iCloud sync is opt-in (default off). When enabled, SwiftData
            // mirrors to the user's *private* CloudKit database — not our
            // servers. The flag is read at launch; toggling needs a restart.
            let syncOn = UserDefaults.standard.bool(forKey: "icloud.sync")
            let configuration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: syncOn ? .automatic : .none
            )
            modelContainer = try ModelContainer(
                for: schema,
                configurations: [configuration]
            )
        } catch {
            // A failure here means the local store is unreadable — there is no
            // safe recovery beyond surfacing it, since all data lives on-device.
            fatalError("无法创建 SwiftData 容器 / Could not create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(purchaseManager)
                .environment(appLock)
                .environment(notifications)
                .environment(health)
                .task { await notifications.refresh() }
        }
        .modelContainer(modelContainer)
    }
}
