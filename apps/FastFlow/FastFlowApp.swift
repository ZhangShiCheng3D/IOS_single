//
//  FastFlowApp.swift
//  FastFlow
//
//  App 入口：配置 SwiftData 容器、注入全局环境对象、首次启动初始化默认断食方案。
//

import SwiftUI
import SwiftData

@main
struct FastFlowApp: App {
    /// SwiftData 模型容器，承载所有持久化数据。
    let modelContainer: ModelContainer

    /// 内购管理器，全局单例，负责 StoreKit 2 交易与解锁状态。
    @State private var purchaseManager = PurchaseManager()

    init() {
        do {
            let schema = Schema([
                FastingSession.self,
                FastingPlan.self,
                WaterEntry.self
            ])
            let configuration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false
            )
            modelContainer = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            // 容器初始化失败属于不可恢复错误，直接终止并打印诊断信息。
            fatalError("无法初始化 SwiftData 容器: \(error)")
        }

        // 首次启动写入内置断食方案。
        FastingPlan.seedDefaultPlansIfNeeded(in: modelContainer.mainContext)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(purchaseManager)
                .tint(.accentColor)
                .task {
                    // 启动时拉取产品并刷新已购状态。
                    await purchaseManager.loadProducts()
                    await purchaseManager.refreshPurchasedState()
                }
        }
        .modelContainer(modelContainer)
    }
}
