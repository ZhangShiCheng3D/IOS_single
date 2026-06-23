//
//  DocScanProApp.swift
//  DocScanPro
//
//  端侧 OCR 文档扫描仪（隐私版）
//  拍照转 PDF + 完全本地 OCR 文字识别，一个字都不上传云端。
//
//  Created by Independent Developer.
//

import SwiftUI
import SwiftData

@main
struct DocScanProApp: App {

    /// SwiftData 容器：所有数据仅保存在设备本地（App 沙盒），不开启 CloudKit 同步。
    /// 这是隐私承诺的技术实现：数据永不离开设备。
    let modelContainer: ModelContainer

    /// 内购 / 买断购买状态管理器，全局单例注入环境。
    @StateObject private var purchaseManager = PurchaseManager.shared

    /// 应用偏好设置（深色模式、OCR 语言等）。
    @StateObject private var appSettings = AppSettings()

    init() {
        do {
            // 显式声明本地存储配置：关闭云同步，确保零上传。
            let configuration = ModelConfiguration(
                "DocScanPro",
                schema: Schema([
                    ScanDocument.self,
                    ScannedPage.self,
                    Folder.self,
                    Tag.self
                ]),
                isStoredInMemoryOnly: false,
                allowsSave: true,
                cloudKitDatabase: .none // 关键：禁止 iCloud，纯本地。
            )

            modelContainer = try ModelContainer(
                for: ScanDocument.self, ScannedPage.self, Folder.self, Tag.self,
                configurations: configuration
            )
        } catch {
            fatalError("无法初始化本地数据库 ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(purchaseManager)
                .environmentObject(appSettings)
                .preferredColorScheme(appSettings.colorSchemePreference.colorScheme)
                .task {
                    // 启动时监听交易更新，恢复购买状态。
                    await purchaseManager.start()
                }
        }
        .modelContainer(modelContainer)
    }
}
