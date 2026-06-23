//
//  ContentView.swift
//  FastFlow
//
//  根视图：构建并持有 ViewModel，承载主 TabView。
//  ViewModel 需要 ModelContext，故在此处依赖环境创建一次后向下传递。
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext

    // 在视图层创建并持有 VM，保证计时器在切换 Tab 时持续存活。
    @State private var fastingViewModel: FastingViewModel?
    @State private var waterViewModel: WaterViewModel?

    var body: some View {
        Group {
            if let fastingViewModel, let waterViewModel {
                MainTabView(fastingViewModel: fastingViewModel, waterViewModel: waterViewModel)
            } else {
                ProgressView()
            }
        }
        .onAppear {
            if fastingViewModel == nil {
                fastingViewModel = FastingViewModel(context: modelContext)
            }
            if waterViewModel == nil {
                waterViewModel = WaterViewModel(context: modelContext)
            }
        }
        .task {
            // 启动即请求通知授权，便于断食/喝水提醒。
            await NotificationManager.shared.requestAuthorization()
        }
    }
}

/// 主标签栏。
private struct MainTabView: View {
    let fastingViewModel: FastingViewModel
    let waterViewModel: WaterViewModel

    var body: some View {
        TabView {
            FastingTimerView(viewModel: fastingViewModel)
                .tabItem { Label("tab.fasting", systemImage: "timer") }

            WaterTrackingView(viewModel: waterViewModel)
                .tabItem { Label("tab.water", systemImage: "drop.fill") }

            TrendsView()
                .tabItem { Label("tab.trends", systemImage: "chart.xyaxis.line") }

            HistoryView()
                .tabItem { Label("tab.history", systemImage: "clock.arrow.circlepath") }

            SettingsView()
                .tabItem { Label("tab.settings", systemImage: "gearshape.fill") }
        }
    }
}

#Preview {
    let container = try! ModelContainer(
        for: FastingSession.self, FastingPlan.self, WaterEntry.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    FastingPlan.seedDefaultPlansIfNeeded(in: container.mainContext)
    return ContentView()
        .modelContainer(container)
        .environment(PurchaseManager())
}
