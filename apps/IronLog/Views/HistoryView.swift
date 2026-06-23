//
//  HistoryView.swift
//  IronLog
//
//  训练历史与趋势。顶部为汇总指标 + 容量/频次图表（Pro），
//  下方为历史训练列表，点击进入详情。
//

import SwiftUI
import SwiftData
import Charts

struct HistoryView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var purchaseManager: PurchaseManager
    @Environment(\.modelContext) private var context

    @Query(
        filter: #Predicate<WorkoutSession> { $0.endDate != nil },
        sort: \WorkoutSession.date, order: .reverse
    ) private var sessions: [WorkoutSession]

    @State private var showPaywall = false
    @State private var showExporter = false

    private var totalVolume: Double { sessions.reduce(0) { $0 + $1.totalVolume } }
    private var volumeTrend: [TrendPoint] { StatsCalculator.volumeTrend(sessions: sessions) }
    private var frequency: [TrendPoint] { StatsCalculator.weeklyFrequency(sessions: sessions) }

    var body: some View {
        NavigationStack {
            Group {
                if sessions.isEmpty {
                    ContentUnavailableView(
                        "history.empty.title",
                        systemImage: "chart.xyaxis.line",
                        description: Text("history.empty.desc")
                    )
                } else {
                    content
                }
            }
            .navigationTitle("tab.history")
            .toolbar {
                if !sessions.isEmpty {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            if purchaseManager.isPro {
                                showExporter = true
                            } else {
                                showPaywall = true
                            }
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                }
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .sheet(isPresented: $showExporter) {
                ExportView(sessions: sessions)
            }
        }
    }

    private var content: some View {
        List {
            // 汇总指标
            Section {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    MetricCard(
                        title: String(localized: "stat.total.workouts"),
                        value: "\(sessions.count)",
                        systemImage: "flame.fill"
                    )
                    MetricCard(
                        title: String(localized: "stat.total.volume"),
                        value: Fmt.volume(totalVolume, unit: settings.weightUnit),
                        systemImage: "scalemass.fill"
                    )
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }

            // 趋势图表（Pro）
            Section("history.trends") {
                if purchaseManager.isPro {
                    volumeChart
                    frequencyChart
                } else {
                    ProLockedRow(feature: String(localized: "history.trends")) {
                        showPaywall = true
                    }
                }
            }

            // 训练列表
            Section("history.sessions") {
                ForEach(sessions) { session in
                    NavigationLink {
                        SessionDetailView(session: session)
                    } label: {
                        SessionListRow(session: session)
                    }
                }
                .onDelete(perform: deleteSessions)
            }
        }
        .listStyle(.insetGrouped)
    }

    private var volumeChart: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("history.volume.byday")
                .font(.caption)
                .foregroundStyle(.secondary)
            Chart(volumeTrend) { point in
                BarMark(
                    x: .value("date", point.date, unit: .day),
                    y: .value("volume", settings.weightUnit.display(fromKg: point.value))
                )
                .foregroundStyle(Color.ironAccent.gradient)
            }
            .frame(height: 160)
        }
        .padding(.vertical, 4)
    }

    private var frequencyChart: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("history.frequency")
                .font(.caption)
                .foregroundStyle(.secondary)
            Chart(frequency) { point in
                BarMark(
                    x: .value("week", point.date, unit: .weekOfYear),
                    y: .value("count", point.value)
                )
                .foregroundStyle(Color.green.gradient)
            }
            .frame(height: 120)
        }
        .padding(.vertical, 4)
    }

    private func deleteSessions(at offsets: IndexSet) {
        for index in offsets {
            context.delete(sessions[index])
        }
        try? context.save()
    }
}

/// 历史列表单行。
struct SessionListRow: View {
    let session: WorkoutSession
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(session.name.isEmpty ? String(localized: "workout.untitled") : session.name)
                    .font(.body.weight(.semibold))
                Spacer()
                Text(Fmt.relativeDay(session.date))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 14) {
                Label("\(session.exercises.count)", systemImage: "figure.strengthtraining.traditional")
                Label("\(session.completedSetCount)", systemImage: "number")
                Label(Fmt.volume(session.totalVolume, unit: settings.weightUnit), systemImage: "scalemass")
                Label(Fmt.duration(session.duration), systemImage: "clock")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    HistoryView()
        .environmentObject(AppSettings())
        .environmentObject(PurchaseManager())
        .modelContainer(PreviewData.container)
}
