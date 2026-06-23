//
//  IronLogApp.swift
//  IronLog
//
//  应用入口。装配 SwiftData 容器、全局环境对象，并在首启时写入内置数据。
//

import SwiftUI
import SwiftData

@main
struct IronLogApp: App {

    /// 共享 SwiftData 容器，纳管所有 @Model。
    let modelContainer: ModelContainer

    @StateObject private var settings = AppSettings()
    @StateObject private var purchaseManager = PurchaseManager()
    @StateObject private var activeWorkout = ActiveWorkoutViewModel()
    @StateObject private var restTimer = RestTimerViewModel()

    init() {
        do {
            let schema = Schema([
                Exercise.self,
                WorkoutSession.self,
                SetEntry.self,
                PersonalRecord.self,
                WorkoutTemplate.self,
                TemplateExercise.self,
            ])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            modelContainer = try ModelContainer(for: schema, configurations: config)
        } catch {
            // 容器创建失败属不可恢复的致命错误。
            fatalError("无法创建 ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(settings)
                .environmentObject(purchaseManager)
                .environmentObject(activeWorkout)
                .environmentObject(restTimer)
                .task {
                    // 首启写入内置动作库与模板。
                    SeedData.seedIfNeeded(modelContainer.mainContext)
                    activeWorkout.configure(context: modelContainer.mainContext)
                    await NotificationManager.shared.requestAuthorization()
                    // 若用户此前已开启 Health 同步，重新建立授权状态——
                    // HealthKitManager.isAuthorized 为内存标记，每次启动需重新确认，
                    // 否则结束训练时 save() 会因未授权而静默跳过。
                    if settings.syncToHealthKit {
                        await HealthKitManager.shared.requestAuthorization()
                    }
                }
        }
        .modelContainer(modelContainer)
    }
}
