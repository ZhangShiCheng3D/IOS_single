//
//  ContentView.swift
//  HabitGrid
//
//  根视图：习惯列表 + 导航到详情/设置/新建。
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(PurchaseManager.self) private var purchaseManager
    @Environment(ThemeManager.self) private var themeManager

    /// 全部习惯，按 sortOrder 排序。
    @Query(sort: \Habit.sortOrder, order: .forward) private var habits: [Habit]

    @State private var viewModel: HabitViewModel?
    @State private var showingForm = false
    @State private var showingSettings = false
    @State private var showingPaywall = false
    @State private var paywallReason: PaywallView.PaywallReason = .general
    @State private var editingHabit: Habit?
    @State private var habitToDelete: Habit?

    private var palette: ColorPalette { themeManager.palette }

    var body: some View {
        NavigationStack {
            Group {
                if habits.isEmpty {
                    EmptyStateView { addHabitTapped() }
                } else {
                    habitList
                }
            }
            .navigationTitle("app.title")
            .toolbar { toolbarContent }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
        }
        .onAppear {
            if viewModel == nil {
                viewModel = HabitViewModel(context: modelContext)
            }
            // 启动时同步一次 Widget 数据。
            WidgetDataBridge.sync(from: modelContext)
        }
        .sheet(isPresented: $showingForm) {
            HabitFormView(habit: nil, existingCount: habits.count)
        }
        .sheet(item: $editingHabit) { habit in
            HabitFormView(habit: habit, existingCount: habits.count)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView(reason: paywallReason)
        }
        .confirmationDialog(
            "delete.confirm.title",
            isPresented: deleteConfirmationBinding,
            titleVisibility: .visible,
            presenting: habitToDelete
        ) { habit in
            Button("common.delete", role: .destructive) {
                withAnimation { vm.delete(habit) }
                habitToDelete = nil
            }
            Button("common.cancel", role: .cancel) {
                habitToDelete = nil
            }
        } message: { habit in
            Text("delete.confirm.message \(habit.name)")
        }
    }

    private var deleteConfirmationBinding: Binding<Bool> {
        Binding(
            get: { habitToDelete != nil },
            set: { if !$0 { habitToDelete = nil } }
        )
    }

    // MARK: - 列表

    private var habitList: some View {
        ScrollView {
            LazyVStack(spacing: 14) {
                // 顶部今日进度条
                TodayProgressHeader(
                    completed: habits.filter { vm.isCompletedToday($0) }.count,
                    total: habits.count,
                    accent: palette.accent
                )
                .padding(.horizontal)
                .padding(.top, 8)

                ForEach(habits) { habit in
                    NavigationLink {
                        HabitDetailView(habit: habit)
                    } label: {
                        HabitRowView(
                            habit: habit,
                            stats: vm.stats(for: habit),
                            palette: palette,
                            isCompletedToday: vm.isCompletedToday(habit),
                            intensity: { vm.intensity(for: habit, on: $0) },
                            onToggleToday: { toggle(habit) }
                        )
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button {
                            editingHabit = habit
                        } label: {
                            Label("common.edit", systemImage: "pencil")
                        }
                        Button(role: .destructive) {
                            habitToDelete = habit
                        } label: {
                            Label("common.delete", systemImage: "trash")
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.bottom, 24)
        }
    }

    // MARK: - 工具栏

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                showingSettings = true
            } label: {
                Image(systemName: "slider.horizontal.3")
            }
            .accessibilityLabel(Text("settings.title"))
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                addHabitTapped()
            } label: {
                Image(systemName: "plus")
                    .fontWeight(.semibold)
            }
            .accessibilityLabel(Text("habit.add"))
        }
    }

    // MARK: - 动作

    private var vm: HabitViewModel {
        // 在 onAppear 前的极少数渲染帧也安全。
        viewModel ?? HabitViewModel(context: modelContext)
    }

    private func addHabitTapped() {
        // 免费版习惯数量限制。
        if !purchaseManager.isPro && habits.count >= FreeTier.maxHabits {
            paywallReason = .habitLimit
            showingPaywall = true
            return
        }
        showingForm = true
    }

    private func toggle(_ habit: Habit) {
        withAnimation(Motion.spring) {
            vm.toggleCheckIn(for: habit)
        }
    }
}

// MARK: - 今日进度头部

private struct TodayProgressHeader: View {
    let completed: Int
    let total: Int
    let accent: Color

    private var progress: Double {
        total == 0 ? 0 : Double(completed) / Double(total)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("today.title")
                    .font(.title3.bold())
                Spacer()
                Text("\(completed)/\(total)")
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.secondary.opacity(0.15))
                    Capsule()
                        .fill(accent)
                        .frame(width: max(0, geo.size.width * progress))
                        .animation(Motion.smooth, value: progress)
                }
            }
            .frame(height: 8)

            if completed == total && total > 0 {
                Label("today.allDone", systemImage: "party.popper.fill")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(accent)
            }
        }
        .padding(16)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .cardShadow()
        .accessibilityElement(children: .combine)
    }
}

// MARK: - 空状态

private struct EmptyStateView: View {
    let onAdd: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "square.grid.3x3.fill")
                .font(.system(size: 56))
                .foregroundStyle(.tint)
                .symbolEffect(.pulse)
            VStack(spacing: 8) {
                Text("empty.title")
                    .font(.title2.bold())
                Text("empty.subtitle")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            Button(action: onAdd) {
                Label("empty.cta", systemImage: "plus")
                    .fontWeight(.semibold)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
        }
        .padding(40)
    }
}

#Preview("Content") {
    ContentView()
        .modelContainer(PreviewData.container)
        .environment(PurchaseManager())
        .environment(ThemeManager())
}
