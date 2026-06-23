//
//  LumenPuzzleApp.swift
//  LumenPuzzle
//
//  极简 3D 光影解谜游戏 —— 买断制、无广告、无内购骚扰。
//  应用入口：配置 SwiftData 容器与全局环境对象。
//

import SwiftUI
import SwiftData

@main
struct LumenPuzzleApp: App {

    /// SwiftData 模型容器：持久化关卡进度与成就。
    /// 使用全局共享容器，确保整个 App 生命周期内只创建一次。
    let modelContainer: ModelContainer

    /// 购买管理器（StoreKit 2）。以 @StateObject 持有，保证唯一实例。
    @StateObject private var purchaseManager = PurchaseManager()

    init() {
        do {
            let schema = Schema([
                LevelProgress.self,
                AchievementRecord.self
            ])
            let configuration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false
            )
            modelContainer = try ModelContainer(
                for: schema,
                configurations: [configuration]
            )
        } catch {
            // 数据库初始化失败属于不可恢复的致命错误，
            // 在开发期直接崩溃以便定位；上架前应确保 Schema 稳定。
            fatalError("无法创建 SwiftData 容器: \(error.localizedDescription)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(purchaseManager)
                .tint(Color.lumenAccent)
        }
        .modelContainer(modelContainer)
    }
}
