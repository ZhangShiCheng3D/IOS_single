//
//  BakeCalcApp.swift
//  BakeCalc
//
//  App 入口。配置 SwiftData 容器与全局环境对象（购买管理器）。
//

import SwiftUI
import SwiftData

@main
struct BakeCalcApp: App {

    /// 全局购买状态管理器（StoreKit 2）。
    @StateObject private var purchaseManager = PurchaseManager()

    /// SwiftData 模型容器。包含已保存配方及其原料明细。
    let modelContainer: ModelContainer

    init() {
        do {
            let schema = Schema([
                SavedRecipe.self,
                SavedIngredient.self
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
            // 容器创建失败属于不可恢复的启动错误，直接终止并给出明确信息。
            fatalError("无法创建 SwiftData ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(purchaseManager)
                .tint(Color.bcAccent)
        }
        .modelContainer(modelContainer)
    }
}
