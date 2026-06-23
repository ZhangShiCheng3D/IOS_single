//
//  PaperGamesApp.swift
//  PaperGames
//
//  应用入口。配置 SwiftData 持久化容器，并将全局环境对象
//  （购买管理器、设置存储）注入到视图层级中。
//

import SwiftUI
import SwiftData

@main
struct PaperGamesApp: App {

    /// SwiftData 模型容器：持久化游戏记录与最佳成绩。
    let modelContainer: ModelContainer

    /// 内购管理器（StoreKit 2）。
    @State private var purchaseManager = PurchaseManager()

    /// 全局设置存储（深色模式、大字号、错误提示等）。
    @State private var settings = SettingsStore()

    init() {
        do {
            modelContainer = try ModelContainer(
                for: GameRecord.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: false)
            )
        } catch {
            // 容器创建失败属于不可恢复错误；记录后崩溃以便尽早发现。
            fatalError("无法创建 SwiftData 容器: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(purchaseManager)
                .environment(settings)
                // 根据用户设置应用配色方案（系统/浅色/深色）。
                .preferredColorScheme(settings.colorScheme.preferred)
                // 大字号模式：放大动态字体下限。
                .dynamicTypeSize(settings.largeFont ? .accessibility1 : .large)
                .tint(.appAccent)
                .task {
                    // 启动时刷新购买状态并监听交易更新。
                    await purchaseManager.start()
                }
        }
        .modelContainer(modelContainer)
    }
}
