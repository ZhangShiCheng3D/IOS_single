//
//  HabitGridApp.swift
//  HabitGrid
//
//  应用入口。配置 SwiftData 容器、StoreKit 购买管理与全局主题状态。
//

import SwiftUI
import SwiftData

@main
struct HabitGridApp: App {

    /// SwiftData 模型容器：持久化习惯与每日打卡记录。
    let modelContainer: ModelContainer

    /// 全局购买状态管理（StoreKit 2）。
    @State private var purchaseManager = PurchaseManager()

    /// 全局主题与外观设置。
    @State private var themeManager = ThemeManager()

    init() {
        do {
            let schema = Schema([Habit.self, HabitEntry.self])
            let configuration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                // 默认纯本地。⚠️ 若要改为 .automatic 开启 CloudKit 同步，必须先去掉
                // Habit.id 上的 @Attribute(.unique)（CloudKit 不支持唯一约束，否则运行时崩溃），
                // 并确认所有关系均有默认值/可选。
                cloudKitDatabase: .none
            )
            modelContainer = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            // 容器初始化失败属于不可恢复错误，直接终止并给出明确诊断信息。
            fatalError("无法初始化 SwiftData 容器: \(error.localizedDescription)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(purchaseManager)
                .environment(themeManager)
                .tint(themeManager.palette.accent)
                .preferredColorScheme(themeManager.colorSchemeOverride)
                .task {
                    // 启动时刷新购买状态，确保跨设备/重装后授权一致。
                    await purchaseManager.refreshPurchasedProducts()
                }
        }
        .modelContainer(modelContainer)
    }
}
