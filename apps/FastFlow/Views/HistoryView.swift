//
//  HistoryView.swift
//  FastFlow
//
//  断食历史记录：按时间倒序列出已完成会话，可删除。
//

import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext

    /// 仅展示已结束的会话，时间倒序。
    @Query(
        filter: #Predicate<FastingSession> { $0.endTime != nil },
        sort: \FastingSession.startTime,
        order: .reverse
    )
    private var sessions: [FastingSession]

    var body: some View {
        NavigationStack {
            Group {
                if sessions.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(sessions) { session in
                            row(session)
                        }
                        .onDelete(perform: delete)
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("tab.history")
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
        }
    }

    private func row(_ session: FastingSession) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill((session.didReachGoal ? Color.goalReached : Color.orange).opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: session.didReachGoal ? "checkmark" : "hourglass.bottomhalf.filled")
                    .foregroundStyle(session.didReachGoal ? Color.goalReached : Color.orange)
            }
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(session.planName)
                        .font(.headline)
                    Text(session.completedDuration.asReadableDuration)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Text(dateRangeText(session))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if session.didReachGoal {
                Text("history.reached")
                    .font(.caption2.bold())
                    .foregroundStyle(Color.goalReached)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.goalReached.opacity(0.12), in: Capsule())
            }
        }
        .padding(.vertical, 4)
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("history.empty.title", systemImage: "clock.arrow.circlepath")
        } description: {
            Text("history.empty.subtitle")
        }
    }

    private func dateRangeText(_ session: FastingSession) -> String {
        let start = session.startTime.formatted(date: .abbreviated, time: .shortened)
        let end = session.endTime?.formatted(date: .omitted, time: .shortened) ?? ""
        return "\(start) → \(end)"
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(sessions[index])
        }
        try? modelContext.save()
        Haptics.tap()
    }
}

#Preview {
    let container = try! ModelContainer(
        for: FastingSession.self, FastingPlan.self, WaterEntry.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let ctx = container.mainContext
    for i in 0..<5 {
        let start = Date().dayOffset(-i).addingTimeInterval(8 * 3600)
        ctx.insert(FastingSession(
            startTime: start,
            endTime: start.addingTimeInterval(Double(14 + i) * 3600),
            targetDuration: 16 * 3600,
            planName: "16:8"
        ))
    }
    return HistoryView().modelContainer(container)
}
