//
//  TrendsView.swift
//  FastFlow
//
//  趋势页：断食时长趋势（Swift Charts）、体重趋势（HealthKit）。
//  30 天范围、体重趋势属高级功能，受付费墙保护。
//

import SwiftUI
import SwiftData
import Charts

/// 单日断食汇总数据点。
private struct DailyFasting: Identifiable {
    let id = UUID()
    let date: Date
    /// 当日累计断食小时。
    let hours: Double
    /// 当日是否达成至少一次目标。
    let reachedGoal: Bool
}

struct TrendsView: View {
    @Environment(PurchaseManager.self) private var purchaseManager
    @Query(sort: \FastingSession.startTime, order: .reverse) private var sessions: [FastingSession]

    @State private var range: TrendRange = .week
    @State private var weightSamples: [WeightSample] = []
    @State private var showPaywall = false

    enum TrendRange: Int, CaseIterable, Identifiable {
        case week = 7
        case month = 30
        var id: Int { rawValue }
        var labelKey: LocalizedStringKey { self == .week ? "trends.range.week" : "trends.range.month" }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    rangePicker
                    fastingChartCard
                    streakCard
                    weightCard
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .navigationTitle("tab.trends")
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .task(id: range) { await loadWeight() }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }

    // MARK: - 范围选择（30 天需高级）

    private var rangePicker: some View {
        Picker("trends.range", selection: $range) {
            ForEach(TrendRange.allCases) { r in
                Text(r.labelKey).tag(r)
            }
        }
        .pickerStyle(.segmented)
        .onChange(of: range) { _, newValue in
            if newValue == .month && !purchaseManager.isPremiumUnlocked {
                range = .week
                showPaywall = true
            }
        }
    }

    // MARK: - 断食趋势图

    private var fastingChartCard: some View {
        let data = dailyData()
        return card(titleKey: "trends.fasting.title", systemImage: "timer") {
            if data.allSatisfy({ $0.hours == 0 }) {
                emptyChart
            } else {
                Chart(data) { item in
                    BarMark(
                        x: .value("trends.axis.day", item.date, unit: .day),
                        y: .value("trends.axis.hours", item.hours)
                    )
                    .foregroundStyle(item.reachedGoal ? Color.goalReached : Color.accentColor)
                    .cornerRadius(4)
                }
                .chartYAxisLabel(NSLocalizedString("trends.axis.hours", comment: ""))
                .frame(height: 220)
            }
        }
    }

    // MARK: - 连续达标统计

    private var streakCard: some View {
        let stats = computeStats()
        return card(titleKey: "trends.stats.title", systemImage: "flame.fill") {
            HStack(spacing: 12) {
                statBox(value: "\(stats.currentStreak)", titleKey: "trends.stats.streak", tint: .orange)
                statBox(value: "\(stats.totalCompleted)", titleKey: "trends.stats.total", tint: .accentColor)
                statBox(
                    value: stats.avgHours > 0 ? String(format: "%.1f", stats.avgHours) : "—",
                    titleKey: "trends.stats.avg",
                    tint: .goalReached
                )
            }
        }
    }

    // MARK: - 体重趋势（高级）

    @ViewBuilder
    private var weightCard: some View {
        card(titleKey: "trends.weight.title", systemImage: "scalemass") {
            if !purchaseManager.isPremiumUnlocked {
                lockedOverlay
            } else if weightSamples.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "heart.text.square")
                        .font(.largeTitle)
                        .foregroundStyle(.tertiary)
                    Text("trends.weight.empty")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else {
                Chart(weightSamples) { sample in
                    LineMark(
                        x: .value("trends.axis.date", sample.date),
                        y: .value("trends.weight.kg", sample.kilograms)
                    )
                    .foregroundStyle(Color.accentColor)
                    .interpolationMethod(.catmullRom)
                    PointMark(
                        x: .value("trends.axis.date", sample.date),
                        y: .value("trends.weight.kg", sample.kilograms)
                    )
                    .foregroundStyle(Color.accentColor)
                }
                .frame(height: 200)
            }
        }
    }

    private var lockedOverlay: some View {
        Button {
            showPaywall = true
        } label: {
            VStack(spacing: 10) {
                Image(systemName: "lock.fill")
                    .font(.title)
                    .foregroundStyle(.secondary)
                Text("trends.locked.title")
                    .font(.headline)
                Text("trends.locked.subtitle")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
        }
        .buttonStyle(.plain)
    }

    // MARK: - 复用组件

    private func card<Content: View>(
        titleKey: LocalizedStringKey,
        systemImage: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(titleKey, systemImage: systemImage)
                .font(.headline)
            content()
        }
        .padding(DS.Spacing.lg - 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle(cornerRadius: DS.Radius.lg)
    }

    private func statBox(value: String, titleKey: LocalizedStringKey, tint: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(.title, design: .rounded).bold())
                .foregroundStyle(tint)
                .monospacedDigit()
            Text(titleKey)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    private var emptyChart: some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.bar")
                .font(.largeTitle)
                .foregroundStyle(.tertiary)
            Text("trends.empty")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }

    // MARK: - 数据计算

    /// 按天聚合断食小时数（仅统计已完成会话）。
    private func dailyData() -> [DailyFasting] {
        let days = range.rawValue
        let calendar = Calendar.current
        let completed = sessions.filter { !$0.isActive }

        return (0..<days).reversed().map { offset in
            let day = Date().dayOffset(-offset)
            let daySessions = completed.filter { calendar.isDate($0.startTime, inSameDayAs: day) }
            let totalHours = daySessions.reduce(0.0) { $0 + $1.completedDuration / 3600 }
            let reached = daySessions.contains { $0.didReachGoal }
            return DailyFasting(date: day, hours: totalHours, reachedGoal: reached)
        }
    }

    /// 统计：当前连续达标天数、总完成次数、平均时长。
    private func computeStats() -> (currentStreak: Int, totalCompleted: Int, avgHours: Double) {
        let completed = sessions.filter { !$0.isActive }
        let totalCompleted = completed.count
        let avgHours = totalCompleted > 0
            ? completed.reduce(0.0) { $0 + $1.completedDuration / 3600 } / Double(totalCompleted)
            : 0

        // 连续达标：从今天往前，存在达标会话则计入，断则停。
        let calendar = Calendar.current
        var streak = 0
        var offset = 0
        while true {
            let day = Date().dayOffset(-offset)
            let reached = completed.contains {
                calendar.isDate($0.startTime, inSameDayAs: day) && $0.didReachGoal
            }
            if reached {
                streak += 1
                offset += 1
            } else if offset == 0 {
                // 今天尚未达标，继续看昨天是否延续。
                offset += 1
            } else {
                break
            }
            if offset > 365 { break }
        }
        return (streak, totalCompleted, avgHours)
    }

    private func loadWeight() async {
        guard purchaseManager.isPremiumUnlocked else { return }
        await HealthKitManager.shared.requestAuthorization()
        weightSamples = await HealthKitManager.shared.fetchWeightSamples(days: range.rawValue)
    }
}

#Preview {
    let container = try! ModelContainer(
        for: FastingSession.self, FastingPlan.self, WaterEntry.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    // 注入示例数据。
    let ctx = container.mainContext
    for i in 0..<6 {
        let start = Date().dayOffset(-i).addingTimeInterval(8 * 3600)
        let session = FastingSession(
            startTime: start,
            endTime: start.addingTimeInterval(Double(15 + i) * 3600),
            targetDuration: 16 * 3600,
            planName: "16:8"
        )
        ctx.insert(session)
    }
    return TrendsView()
        .modelContainer(container)
        .environment(PurchaseManager())
}
