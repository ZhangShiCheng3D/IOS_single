//
//  ContentView.swift
//  PaperGames
//
//  根视图。底部分为「游戏」「统计」「设置」三个标签页。
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("tab.games", systemImage: "gamecontroller.fill")
                }

            StatsView()
                .tabItem {
                    Label("tab.stats", systemImage: "chart.bar.fill")
                }

            SettingsView()
                .tabItem {
                    Label("tab.settings", systemImage: "gearshape.fill")
                }
        }
    }
}

#Preview {
    ContentView()
        .environment(PurchaseManager())
        .environment(SettingsStore())
        .modelContainer(for: GameRecord.self, inMemory: true)
}
