//
//  SeniorHelperApp.swift
//  SeniorHelper
//
//  银发友好工具集 —— 放大镜 / 用药提醒
//  App 入口：配置 SwiftData 容器、注入全局环境对象。
//

import SwiftUI
import SwiftData

@main
struct SeniorHelperApp: App {

    /// 全局购买状态管理器（StoreKit 2）。
    @State private var purchaseManager = PurchaseManager()

    /// 全局语音播报管理器。
    @State private var speechManager = SpeechManager()

    /// SwiftData 模型容器：持久化用药计划与紧急联系人。
    let modelContainer: ModelContainer

    init() {
        let schema = Schema([
            Medication.self,
            EmergencyContact.self
        ])
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )
        do {
            modelContainer = try ModelContainer(
                for: schema,
                configurations: [configuration]
            )
        } catch {
            // 在单机离线应用中，容器创建失败属于不可恢复的致命错误。
            fatalError("无法创建 SwiftData 容器: \(error.localizedDescription)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(purchaseManager)
                .environment(speechManager)
                // 全局强制支持 Dynamic Type，最大可达辅助级超大字号。
                .dynamicTypeSize(.large ... .accessibility5)
        }
        .modelContainer(modelContainer)
    }
}
