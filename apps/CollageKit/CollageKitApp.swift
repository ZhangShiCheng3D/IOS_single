//
//  CollageKitApp.swift
//  CollageKit
//
//  App 入口。配置 SwiftData 容器与全局购买管理器。
//

import SwiftUI
import SwiftData

@main
struct CollageKitApp: App {
    /// 全局内购管理器。
    @StateObject private var store = PurchaseManager()

    /// SwiftData 容器，注册全部持久化模型。
    let modelContainer: ModelContainer = {
        let schema = Schema([
            CollageProject.self,
            CollagePhoto.self,
            CollageText.self,
            UserPreset.self
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
                .environmentObject(store)
        }
        .modelContainer(modelContainer)
    }
}
