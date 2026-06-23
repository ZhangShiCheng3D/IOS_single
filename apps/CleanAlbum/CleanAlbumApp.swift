//
//  CleanAlbumApp.swift
//  CleanAlbum
//
//  应用入口。配置 SwiftData 容器、注入全局购买管理器。
//

import SwiftUI
import SwiftData

@main
struct CleanAlbumApp: App {

    /// 全局购买状态管理器（StoreKit 2）。
    @State private var purchaseManager = PurchaseManager()

    /// SwiftData 容器：持久化购买记录与扫描设置。
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            AppSettings.self,
            CleanupRecord.self
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("无法创建 ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(purchaseManager)
                .task {
                    // 启动即监听交易更新，确保购买状态实时同步。
                    await purchaseManager.start()
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
