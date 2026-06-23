//
//  HabitDetailView.swift
//  HabitGrid
//
//  习惯详情：完整热力图（可点击补卡）+ 统计 + 导出截图。
//

import SwiftUI
import SwiftData

struct HabitDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(ThemeManager.self) private var themeManager
    @Environment(PurchaseManager.self) private var purchaseManager

    let habit: Habit

    @State private var showingForm = false
    @State private var showingShare = false
    @State private var showingPaywall = false
    #if canImport(UIKit)
    @State private var exportedImage: UIImage?
    #endif

    private var palette: ColorPalette { themeManager.palette }
    private var habitPalette: ColorPalette {
        ColorPalette(
            id: palette.id,
            nameKey: palette.nameKey,
            levels: Color.heatLevels(fromHex: habit.colorHex),
            accentHex: habit.colorHex,
            isPremium: palette.isPremium
        )
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                heatmapCard
                statsGrid
            }
            .padding()
        }
        .navigationTitle(habit.name)
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showingForm = true
                    } label: {
                        Label("common.edit", systemImage: "pencil")
                    }
                    Button {
                        exportTapped()
                    } label: {
                        Label("detail.export", systemImage: "square.and.arrow.up")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingForm) {
            HabitFormView(habit: habit, existingCount: 0)
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView(reason: .general)
        }
        #if canImport(UIKit)
        .sheet(isPresented: $showingShare) {
            if let image = exportedImage {
                ShareSheet(items: [image])
                    .presentationDetents([.medium, .large])
            }
        }
        #endif
    }

    // MARK: - 热力图卡片

    private var heatmapCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: habit.iconName)
                    .font(.title2)
                    .foregroundStyle(habit.color)
                    .frame(width: 48, height: 48)
                    .background(habit.color.opacity(0.15), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text(habit.name).font(.title3.bold())
                    Text(habit.frequency.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            HeatmapView(
                intensity: { intensity(on: $0) },
                palette: habitPalette,
                onTap: { toggle(on: $0) }
            )

            HStack {
                Text("detail.tapHint")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Spacer()
                HeatmapLegend(palette: habitPalette)
            }
        }
        .padding(18)
        .background(.background, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .cardShadow()
    }

    // MARK: - 统计网格

    private var statsGrid: some View {
        let stats = currentStats
        return VStack(spacing: 14) {
            HStack(spacing: 12) {
                StatCard(icon: "flame.fill",
                         value: "\(stats.currentStreak)",
                         title: "stats.currentStreak",
                         accent: habit.color)
                StatCard(icon: "trophy.fill",
                         value: "\(stats.longestStreak)",
                         title: "stats.longestStreak",
                         accent: habit.color)
            }
            HStack(spacing: 12) {
                StatCard(icon: "checkmark.circle.fill",
                         value: "\(stats.totalCompletions)",
                         title: "stats.total",
                         accent: habit.color)
                StatCard(icon: "percent",
                         value: "\(Int(stats.completionRate * 100))%",
                         title: "stats.completionRate",
                         accent: habit.color)
            }
        }
    }

    // MARK: - 计算

    private var currentStats: HabitStats {
        let days = Set(habit.entries.map { $0.day })
        return HabitStatistics.compute(
            completedDays: days,
            frequency: habit.frequency,
            weeklyTarget: habit.weeklyTarget,
            createdAt: habit.createdAt
        )
    }

    private func intensity(on date: Date) -> Int {
        let day = date.startOfDay
        return habit.entries.first(where: { $0.day == day })?.intensity ?? 0
    }

    private func toggle(on date: Date) {
        let vm = HabitViewModel(context: modelContext)
        withAnimation(Motion.spring) {
            vm.toggleCheckIn(for: habit, on: date)
        }
    }

    // MARK: - 导出

    private func exportTapped() {
        // 导出为付费功能。
        guard purchaseManager.isPro else {
            showingPaywall = true
            return
        }
        #if canImport(UIKit)
        let card = ShareableHeatmapCard(habit: habit, stats: currentStats, palette: habitPalette)
            .environment(themeManager)
        if let image = HeatmapExporter.render(card.frame(width: 380)) {
            exportedImage = image
            showingShare = true
        }
        #endif
    }
}

/// 用于导出/分享的精美热力图卡片（带品牌水印）。
struct ShareableHeatmapCard: View {
    let habit: Habit
    let stats: HabitStats
    let palette: ColorPalette
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 12) {
                Image(systemName: habit.iconName)
                    .font(.title2)
                    .foregroundStyle(habit.color)
                    .frame(width: 46, height: 46)
                    .background(habit.color.opacity(0.18), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text(habit.name).font(.title3.bold())
                    Text("detail.streakLine \(stats.currentStreak)")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
            }

            HeatmapView(
                intensity: { date in
                    let day = date.startOfDay
                    return habit.entries.first(where: { $0.day == day })?.intensity ?? 0
                },
                palette: palette,
                onTap: nil,
                weeks: 26,
                showsLabels: false,
                cellSize: 11,
                spacing: 2.5
            )

            HStack {
                statBlock("\(stats.currentStreak)", "stats.currentStreak")
                Divider().frame(height: 28)
                statBlock("\(stats.longestStreak)", "stats.longestStreak")
                Divider().frame(height: 28)
                statBlock("\(Int(stats.completionRate * 100))%", "stats.completionRate")
            }

            HStack {
                Spacer()
                Label("app.title", systemImage: "square.grid.3x3.fill")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(22)
        .background(scheme == .dark ? Color(white: 0.1) : .white)
    }

    private func statBlock(_ value: String, _ title: LocalizedStringKey) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.headline).monospacedDigit()
            Text(title).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview("Detail") {
    NavigationStack {
        HabitDetailView(habit: PreviewData.sampleHabit)
            .modelContainer(PreviewData.container)
            .environment(ThemeManager())
            .environment(PurchaseManager())
    }
}
