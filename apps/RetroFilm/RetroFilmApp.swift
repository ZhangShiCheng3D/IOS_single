//
//  RetroFilmApp.swift
//  RetroFilm
//
//  App entry point. Wires up the SwiftData model container for the in-app photo
//  library and provides the shared `PurchaseManager` to the whole view tree.
//

import SwiftUI
import SwiftData

@main
struct RetroFilmApp: App {

    /// One purchase manager for the app lifetime — owns StoreKit state.
    @StateObject private var store = PurchaseManager()

    /// SwiftData container for the captured-photo library.
    let modelContainer: ModelContainer = {
        let schema = Schema([CapturedPhoto.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            // A failed store is unrecoverable; fail loudly in development.
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .tint(Theme.accent)
        }
        .modelContainer(modelContainer)
    }
}
