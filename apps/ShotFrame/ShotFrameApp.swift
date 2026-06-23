//
//  ShotFrameApp.swift
//  ShotFrame
//
//  App entry point. Sets up the SwiftData container for saved projects and
//  injects the shared StoreKit purchase manager into the environment.
//

import SwiftUI
import SwiftData

@main
struct ShotFrameApp: App {

    /// Single source of truth for the Pro entitlement, shared app-wide.
    @StateObject private var purchases = PurchaseManager()

    /// SwiftData container holding the user's saved projects.
    let modelContainer: ModelContainer = {
        do {
            return try ModelContainer(for: ShotProject.self)
        } catch {
            // A failure here means the on-disk store is irrecoverable; fall back
            // to an in-memory store so the app still launches.
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            return try! ModelContainer(for: ShotProject.self, configurations: config)
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(purchases)
                .tint(Color("AccentColor"))
                .task { await purchases.load() }
        }
        .modelContainer(modelContainer)
    }
}
