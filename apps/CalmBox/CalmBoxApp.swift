//
//  CalmBoxApp.swift
//  CalmBox
//
//  应用入口：配置 SwiftData 容器、音频会话、全局环境对象。
//

import SwiftUI
import SwiftData

@main
struct CalmBoxApp: App {

    /// SwiftData 容器：持久化收藏、冥想记录与本地设置。
    let modelContainer: ModelContainer

    /// 内购管理器，负责 StoreKit 2 商品加载与购买状态。
    @State private var purchaseManager = PurchaseManager()

    /// 音频管理器，负责白噪音混音与后台播放。
    @State private var audioManager = AudioManager()

    /// 触觉管理器，负责 Core Haptics 自定义震动。
    @State private var hapticManager = HapticManager()

    init() {
        do {
            let schema = Schema([
                FavoriteRecord.self,
                MeditationSession.self,
                MixerPreset.self
            ])
            let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            modelContainer = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            // 持久化容器初始化失败属于不可恢复错误，直接终止以暴露问题。
            fatalError("无法创建 SwiftData ModelContainer: \(error.localizedDescription)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(purchaseManager)
                .environment(audioManager)
                .environment(hapticManager)
                .task {
                    // 启动时同步用户的触觉开关偏好，避免设置在打开设置页前不生效。
                    hapticManager.isEnabled = UserDefaults.standard
                        .object(forKey: AppConstants.DefaultsKey.hapticsEnabled) as? Bool ?? true
                    // 预热触觉引擎并拉取商品信息。
                    hapticManager.prepare()
                    await purchaseManager.start()
                }
        }
        .modelContainer(modelContainer)
    }
}
