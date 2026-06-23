//
//  ContentView.swift
//  OneWord
//
//  The main tab interface: Today, Calendar, Trends, and Settings.
//

import SwiftUI

struct ContentView: View {
    @State private var selection: Tab = .today

    enum Tab: Hashable {
        case today, calendar, trends, settings
    }

    var body: some View {
        TabView(selection: $selection) {
            TodayView()
                .tabItem {
                    Label("tab.today", systemImage: "sun.max.fill")
                }
                .tag(Tab.today)

            CalendarView()
                .tabItem {
                    Label("tab.calendar", systemImage: "calendar")
                }
                .tag(Tab.calendar)

            TrendsView()
                .tabItem {
                    Label("tab.trends", systemImage: "chart.xyaxis.line")
                }
                .tag(Tab.trends)

            SettingsView()
                .tabItem {
                    Label("tab.settings", systemImage: "gearshape.fill")
                }
                .tag(Tab.settings)
        }
        .tint(Theme.accent)
    }
}

#Preview {
    ContentView()
        .environment(AppLock())
        .environment(PurchaseManager())
        .modelContainer(PreviewData.container)
}
