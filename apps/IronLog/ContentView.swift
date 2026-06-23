//
//  ContentView.swift
//  IronLog
//
//  根视图：底部标签导航 + 全局休息计时器浮层。
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var restTimer: RestTimerViewModel
    @Environment(\.scenePhase) private var scenePhase

    @State private var selectedTab: Tab = .workout

    enum Tab: Hashable {
        case workout, history, templates, exercises, settings
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            WorkoutView()
                .tabItem { Label("tab.workout", systemImage: "dumbbell.fill") }
                .tag(Tab.workout)

            HistoryView()
                .tabItem { Label("tab.history", systemImage: "chart.xyaxis.line") }
                .tag(Tab.history)

            TemplatesView()
                .tabItem { Label("tab.templates", systemImage: "list.clipboard.fill") }
                .tag(Tab.templates)

            ExerciseLibraryView()
                .tabItem { Label("tab.exercises", systemImage: "books.vertical.fill") }
                .tag(Tab.exercises)

            SettingsView()
                .tabItem { Label("tab.settings", systemImage: "gearshape.fill") }
                .tag(Tab.settings)
        }
        .tint(.ironAccent)
        // 休息计时器浮层：进行中时悬浮于标签栏上方，跨页面可见。
        .safeAreaInset(edge: .bottom) {
            if restTimer.isRunning {
                RestTimerBar()
                    .padding(.horizontal)
                    .padding(.bottom, 4)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: restTimer.isRunning)
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                restTimer.refreshFromBackground()
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppSettings())
        .environmentObject(PurchaseManager())
        .environmentObject(ActiveWorkoutViewModel())
        .environmentObject(RestTimerViewModel())
        .modelContainer(PreviewData.container)
}
