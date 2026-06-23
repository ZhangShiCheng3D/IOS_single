//
//  ContentView.swift
//  OneWord
//
//  The main tab interface: Today, Calendar, Trends, and Settings.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selection: Tab = .today
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.modelContext) private var modelContext

    /// Today's entry, so a deep-link/Siri "record" edits rather than duplicates.
    @Query(sort: \DiaryEntry.date, order: .reverse) private var entries: [DiaryEntry]
    @State private var showRecord = false

    private var todayEntry: DiaryEntry? {
        entries.first { $0.date.isSameDay(as: Date()) }
    }

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
        .onOpenURL { url in
            if url == OneWordShared.recordURL { openRecord() }
        }
        .onChange(of: scenePhase) { _, phase in
            // Siri/Shortcuts intent sets a pending flag; honor it on activation.
            if phase == .active, OneWordShared.consumePendingRecord() {
                openRecord()
            }
        }
        .sheet(isPresented: $showRecord) {
            EntryEditorView(date: Date(), existing: todayEntry)
        }
        #if DEBUG
        .task {
            // Launch with `-seedOnLaunch YES` to auto-fill sample entries.
            if ProcessInfo.processInfo.arguments.contains("-seedOnLaunch"), entries.isEmpty {
                DebugSeed.seed(into: modelContext, existing: entries)
            }
        }
        #endif
    }

    private func openRecord() {
        selection = .today
        showRecord = true
    }
}

#Preview {
    ContentView()
        .environment(AppLock())
        .environment(PurchaseManager())
        .environment(NotificationManager())
        .environment(HealthManager())
        .modelContainer(PreviewData.container)
}
