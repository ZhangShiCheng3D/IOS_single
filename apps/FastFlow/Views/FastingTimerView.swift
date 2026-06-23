//
//  FastingTimerView.swift
//  FastFlow
//
//  断食计时主界面：圆环计时、开始/结束、方案选择、回填开始时间。
//

import SwiftUI
import SwiftData

struct FastingTimerView: View {
    var viewModel: FastingViewModel

    /// 所有断食方案，按"内置在前 + 创建时间"排序。
    @Query(sort: \FastingPlan.createdAt, order: .forward) private var plans: [FastingPlan]

    /// 当前选中的方案 ID（开始断食时使用）。
    @State private var selectedPlanID: UUID?
    @State private var showPlanPicker = false
    @State private var showStartTimeEditor = false
    @State private var showEndConfirm = false
    @State private var draftStartTime = Date.now

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    ringSection
                    if viewModel.isFasting {
                        activeStats
                        endButton
                    } else {
                        planSelector
                        startButton
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 32)
            }
            .navigationTitle("tab.fasting")
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .onAppear(perform: ensureSelection)
            .sheet(isPresented: $showPlanPicker) {
                PlanPickerView(selectedPlanID: $selectedPlanID)
            }
            .sheet(isPresented: $showStartTimeEditor) {
                startTimeEditor
            }
            .confirmationDialog(
                "fasting.end.confirm.title",
                isPresented: $showEndConfirm,
                titleVisibility: .visible
            ) {
                Button("fasting.end", role: .destructive) {
                    withAnimation(DS.Motion.spring) { viewModel.endFasting() }
                }
                Button("common.cancel", role: .cancel) {}
            } message: {
                Text(viewModel.hasReachedGoal
                     ? LocalizedStringKey("fasting.end.confirm.reached")
                     : LocalizedStringKey("fasting.end.confirm.early"))
            }
        }
    }

    // MARK: - 圆环

    private var ringSection: some View {
        CircularProgressRing(
            progress: viewModel.isFasting ? viewModel.progress : 0,
            gradient: ringGradient
        ) {
            VStack(spacing: 8) {
                if viewModel.isFasting {
                    Text(viewModel.isFasting ? currentPlanName : "—")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(viewModel.elapsed.asClockString)
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                    Text(statusText)
                        .font(.footnote)
                        .foregroundStyle(viewModel.hasReachedGoal ? Color.goalReached : .secondary)
                } else {
                    Image(systemName: "moon.stars.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(Color.accentColor)
                    Text("fasting.idle.title")
                        .font(.headline)
                    Text("fasting.idle.subtitle")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .frame(height: 300)
        .padding(.top, 8)
    }

    private var ringGradient: Gradient {
        viewModel.hasReachedGoal
            ? Gradient(colors: [Color.goalReached, Color.goalReached.opacity(0.7)])
            : Gradient(colors: [.accentColor, Color.goalReached])
    }

    // MARK: - 进行中统计

    private var activeStats: some View {
        HStack(spacing: 12) {
            StatChip(
                icon: "play.circle",
                title: "fasting.startedAt",
                value: timeString(viewModel.activeSession?.startTime)
            )
            StatChip(
                icon: "flag.checkered",
                title: "fasting.goalAt",
                value: timeString(viewModel.scheduledEndTime),
                tint: .goalReached
            )
            StatChip(
                icon: viewModel.hasReachedGoal ? "checkmark.circle" : "hourglass",
                title: viewModel.hasReachedGoal ? "fasting.completed" : "fasting.remaining",
                value: viewModel.hasReachedGoal
                    ? viewModel.elapsed.asReadableDuration
                    : viewModel.remaining.asClockString,
                tint: viewModel.hasReachedGoal ? .goalReached : .orange
            )
        }
    }

    private var endButton: some View {
        VStack(spacing: 10) {
            Button(role: .destructive) {
                Haptics.tap()
                showEndConfirm = true
            } label: {
                Label("fasting.end", systemImage: "stop.circle.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
            .controlSize(.large)

            Button {
                draftStartTime = viewModel.activeSession?.startTime ?? .now
                showStartTimeEditor = true
            } label: {
                Label("fasting.editStart", systemImage: "pencil")
                    .font(.subheadline)
            }
        }
    }

    // MARK: - 方案选择与开始

    private var planSelector: some View {
        Button {
            showPlanPicker = true
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("fasting.selectedPlan")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(currentPlanName)
                        .font(.title3.bold())
                    if let plan = selectedPlan {
                        Text(plan.subtitle)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.tertiary)
            }
            .padding(DS.Spacing.lg - 6)
            .cardStyle(cornerRadius: DS.Radius.lg)
        }
        .buttonStyle(.plain)
        .accessibilityHint(Text("fasting.selectPlan.a11yHint"))
    }

    private var startButton: some View {
        Button {
            guard let plan = selectedPlan else { return }
            withAnimation { viewModel.startFasting(plan: plan) }
        } label: {
            Label("fasting.start", systemImage: "play.circle.fill")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(selectedPlan == nil)
    }

    // MARK: - 开始时间编辑器

    private var startTimeEditor: some View {
        NavigationStack {
            Form {
                DatePicker(
                    "fasting.startTime",
                    selection: $draftStartTime,
                    in: ...Date.now,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(.graphical)
            }
            .navigationTitle("fasting.editStart")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel") { showStartTimeEditor = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.save") {
                        viewModel.adjustStartTime(to: draftStartTime)
                        showStartTimeEditor = false
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    // MARK: - 辅助

    private var selectedPlan: FastingPlan? {
        plans.first { $0.id == selectedPlanID } ?? plans.first
    }

    private var currentPlanName: String {
        if viewModel.isFasting {
            return viewModel.activeSession?.planName ?? "—"
        }
        return selectedPlan?.name ?? "—"
    }

    private var statusText: String {
        if viewModel.hasReachedGoal {
            return NSLocalizedString("fasting.status.reached", comment: "")
        }
        return String(
            format: NSLocalizedString("fasting.status.progress", comment: ""),
            Int(viewModel.progress * 100)
        )
    }

    private func ensureSelection() {
        if selectedPlanID == nil {
            selectedPlanID = plans.first?.id
        }
    }

    private func timeString(_ date: Date?) -> String {
        guard let date else { return "—" }
        return date.formatted(date: .omitted, time: .shortened)
    }
}

#Preview {
    let container = try! ModelContainer(
        for: FastingSession.self, FastingPlan.self, WaterEntry.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    FastingPlan.seedDefaultPlansIfNeeded(in: container.mainContext)
    return FastingTimerView(viewModel: FastingViewModel(context: container.mainContext))
        .modelContainer(container)
}
