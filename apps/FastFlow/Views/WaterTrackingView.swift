//
//  WaterTrackingView.swift
//  FastFlow
//
//  喝水追踪界面：每日进度环、快捷添加、今日记录列表、目标设置。
//

import SwiftUI
import SwiftData

struct WaterTrackingView: View {
    var viewModel: WaterViewModel

    /// 全部饮水记录（时间倒序），由 SwiftData 驱动，增删自动刷新 UI。
    @Query(sort: \WaterEntry.timestamp, order: .reverse) private var allEntries: [WaterEntry]

    @State private var showGoalEditor = false
    @State private var customAmount = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DS.Spacing.lg) {
                    progressRing
                    quickAddRow
                    customAddRow
                    todayList
                }
                .padding(.horizontal, DS.Spacing.lg - 4)
                .padding(.vertical, DS.Spacing.md)
                .animation(DS.Motion.spring, value: todayTotalML)
            }
            .navigationTitle("tab.water")
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showGoalEditor = true
                    } label: {
                        Image(systemName: "target")
                    }
                    .accessibilityLabel(Text("water.editGoal"))
                }
            }
            .sheet(isPresented: $showGoalEditor) {
                goalEditor
            }
        }
    }

    // MARK: - 今日派生数据

    /// 今日饮水记录（从全部记录中过滤当天）。
    private var todayEntries: [WaterEntry] {
        let start = Date.now.startOfDay
        let end = start.dayOffset(1)
        return allEntries.filter { $0.timestamp >= start && $0.timestamp < end }
    }

    /// 今日已喝总量（毫升）。
    private var todayTotalML: Int {
        todayEntries.reduce(0) { $0 + $1.amountML }
    }

    /// 今日进度 0...1。
    private var todayProgress: Double {
        guard viewModel.dailyGoalML > 0 else { return 0 }
        return min(1.0, Double(todayTotalML) / Double(viewModel.dailyGoalML))
    }

    /// 今日剩余目标（毫升）。
    private var remainingML: Int {
        max(0, viewModel.dailyGoalML - todayTotalML)
    }

    // MARK: - 进度环

    private var progressRing: some View {
        CircularProgressRing(
            progress: todayProgress,
            gradient: Gradient(colors: [Color.water, Color.water.opacity(0.6)]),
            lineWidth: 16
        ) {
            VStack(spacing: 6) {
                Image(systemName: "drop.fill")
                    .font(.title)
                    .foregroundStyle(Color.water)
                Text("\(todayTotalML)")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                Text(String(
                    format: NSLocalizedString("water.ofGoal.format", comment: ""),
                    viewModel.dailyGoalML
                ))
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
        }
        .frame(height: 260)
        .padding(.top, 8)
    }

    // MARK: - 快捷添加

    private var quickAddRow: some View {
        HStack(spacing: 12) {
            ForEach(WaterEntry.quickAmounts, id: \.self) { amount in
                Button {
                    viewModel.addWater(amount)
                } label: {
                    VStack(spacing: DS.Spacing.xs) {
                        Image(systemName: "drop.fill")
                            .foregroundStyle(Color.water)
                        Text("\(amount)")
                            .font(.headline)
                            .monospacedDigit()
                        Text("ml")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DS.Spacing.md - 2)
                    .cardStyle()
                }
                .buttonStyle(.plain)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(String(
                    format: NSLocalizedString("water.quickAdd.a11y", comment: ""),
                    amount
                )))
            }
        }
    }

    private var customAddRow: some View {
        HStack {
            TextField("water.customAmount", text: $customAmount)
                .keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)
            Button {
                if let amount = Int(customAmount), amount > 0 {
                    viewModel.addWater(amount)
                    customAmount = ""
                }
            } label: {
                Text("water.add")
                    .fontWeight(.semibold)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.water)
            .disabled(Int(customAmount) == nil)
        }
    }

    // MARK: - 今日记录

    private var todayList: some View {
        let entries = todayEntries
        return VStack(alignment: .leading, spacing: DS.Spacing.sm + 4) {
            HStack {
                Text("water.today.records")
                    .font(.headline)
                Spacer()
                Text(String(
                    format: NSLocalizedString("water.remaining.format", comment: ""),
                    remainingML
                ))
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            if entries.isEmpty {
                emptyState
            } else {
                VStack(spacing: 0) {
                    ForEach(entries) { entry in
                        HStack {
                            Image(systemName: "drop.fill")
                                .foregroundStyle(Color.water)
                            Text("\(entry.amountML) ml")
                                .font(.body)
                            Spacer()
                            Text(entry.timestamp.formatted(date: .omitted, time: .shortened))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Button(role: .destructive) {
                                Haptics.tap()
                                viewModel.delete(entry)
                            } label: {
                                Image(systemName: "trash")
                                    .font(.caption)
                            }
                            .buttonStyle(.borderless)
                            .padding(.leading, DS.Spacing.sm)
                            .accessibilityLabel(Text("water.delete.a11y"))
                        }
                        .padding(.vertical, DS.Spacing.sm + 4)
                        if entry.id != entries.last?.id {
                            Divider()
                        }
                    }
                }
                .padding(.horizontal, DS.Spacing.md)
                .cardStyle()
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "drop")
                .font(.largeTitle)
                .foregroundStyle(.tertiary)
            Text("water.empty")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DS.Spacing.xl)
        .cardStyle()
    }

    // MARK: - 目标编辑

    private var goalEditor: some View {
        NavigationStack {
            Form {
                Section("water.goal.title") {
                    Stepper(value: Binding(
                        get: { viewModel.dailyGoalML },
                        set: { viewModel.dailyGoalML = $0 }
                    ), in: 500...5000, step: 100) {
                        HStack {
                            Text("water.goal.daily")
                            Spacer()
                            Text("\(viewModel.dailyGoalML) ml")
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                    }
                }
                Section {
                    Toggle("water.sync.health", isOn: Binding(
                        get: { viewModel.syncToHealth },
                        set: { newValue in
                            viewModel.syncToHealth = newValue
                            if newValue {
                                Task { await HealthKitManager.shared.requestAuthorization() }
                            }
                        }
                    ))
                } footer: {
                    Text("water.sync.footer")
                }
            }
            .navigationTitle("water.editGoal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.done") { showGoalEditor = false }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    let container = try! ModelContainer(
        for: FastingSession.self, FastingPlan.self, WaterEntry.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    return WaterTrackingView(viewModel: WaterViewModel(context: container.mainContext))
        .modelContainer(container)
}
