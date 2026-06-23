//
//  WorkoutView.swift
//  IronLog
//
//  训练主页：无进行中训练时展示开始选项与上次训练摘要；
//  有进行中训练时切到 ActiveWorkoutView。
//

import SwiftUI
import SwiftData

struct WorkoutView: View {
    @EnvironmentObject private var activeWorkout: ActiveWorkoutViewModel
    @Environment(\.modelContext) private var context

    var body: some View {
        NavigationStack {
            Group {
                if activeWorkout.isWorkoutActive {
                    ActiveWorkoutView()
                } else {
                    StartWorkoutView()
                }
            }
            .navigationTitle("tab.workout")
        }
        .onAppear { activeWorkout.configure(context: context) }
    }
}

/// 无进行中训练时的起始页。
private struct StartWorkoutView: View {
    @EnvironmentObject private var activeWorkout: ActiveWorkoutViewModel
    @Environment(\.modelContext) private var context

    /// 最近完成的训练，用于「再来一次」。
    @Query(
        filter: #Predicate<WorkoutSession> { $0.endDate != nil },
        sort: \WorkoutSession.date, order: .reverse
    ) private var recentSessions: [WorkoutSession]

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 大按钮：开始空白训练
                Button {
                    Haptics.impact(.heavy)
                    activeWorkout.startEmptyWorkout()
                } label: {
                    VStack(spacing: 10) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 44))
                        Text("workout.start.empty")
                            .font(.title3.bold())
                        Text("workout.start.empty.sub")
                            .font(.footnote)
                            .opacity(0.9)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 28)
                    .background(Color.ironAccent.gradient, in: RoundedRectangle(cornerRadius: Theme.heroCorner, style: .continuous))
                    .foregroundStyle(.white)
                    .shadow(color: Color.ironAccent.opacity(0.35), radius: 12, y: 6)
                }
                .accessibilityLabel(Text("workout.start.empty"))
                .accessibilityHint(Text("workout.start.empty.sub"))

                if let last = recentSessions.first {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("workout.last")
                            .font(.headline)
                        SessionSummaryCard(session: last)
                        Button {
                            // 以上次训练涉及的动作快速开练。
                            Haptics.impact()
                            activeWorkout.startEmptyWorkout(name: last.name)
                            for ex in last.exercises {
                                activeWorkout.addExercise(ex)
                            }
                        } label: {
                            Label("workout.repeat", systemImage: "arrow.clockwise")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                        .tint(.ironAccent)
                    }
                } else {
                    ContentUnavailableView(
                        "workout.empty.title",
                        systemImage: "dumbbell",
                        description: Text("workout.empty.desc")
                    )
                    .padding(.top, 40)
                }
            }
            .padding()
        }
    }
}

#Preview("起始页") {
    WorkoutView()
        .environmentObject(AppSettings())
        .environmentObject(PurchaseManager())
        .environmentObject(ActiveWorkoutViewModel())
        .environmentObject(RestTimerViewModel())
        .modelContainer(PreviewData.container)
}
