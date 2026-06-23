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

    /// The SwiftData container holding all diary entries. Stored locally only.
    let modelContainer: ModelContainer

    @MainActor
    init() {
        do {
            let schema = Schema([DiaryEntry.self])
            let configuration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false
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
        }
        .modelContainer(modelContainer)
    }
}
