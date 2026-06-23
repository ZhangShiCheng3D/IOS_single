//
//  PixelStudioApp.swift
//  PixelStudio
//
//  App 入口。配置 SwiftData 容器与全局 PurchaseManager。
//

import SwiftUI
import SwiftData

@main
struct PixelStudioApp: App {
    /// 全局买断状态管理。
    @StateObject private var purchaseManager = PurchaseManager()

    /// SwiftData 容器，持久化所有作品。
    let modelContainer: ModelContainer = {
        let schema = Schema([PixelProject.self, PixelFrame.self, PixelLayer.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: config)
        } catch {
            fatalError("无法创建 ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(purchaseManager)
                .task {
                    await purchaseManager.loadProducts()
                }
        }
        .modelContainer(modelContainer)
    }
}
