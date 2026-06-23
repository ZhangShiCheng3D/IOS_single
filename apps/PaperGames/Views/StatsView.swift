//
//  StatsView.swift
//  PaperGames
//
//  统计页。按难度展示数独完成局数与最佳成绩，并汇总总览。
//

import SwiftUI
import SwiftData

struct StatsView: View {
    @Query(sort: \GameRecord.completedAt, order: .reverse) private var records: [GameRecord]

    var body: some View {
        NavigationStack {
            Group {
                if records.isEmpty {
                    emptyState
                } else {
                    statsList
                }
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle(Text("tab.stats"))
        }
    }

    // MARK: - 空状态

    private var emptyState: some View {
        ContentUnavailableView {
            Label("stats.empty.title", systemImage: "chart.bar.xaxis")
        } description: {
            Text("stats.empty.desc")
        }
    }

    // MARK: - 列表

    private var statsList: some View {
        List {
            Section("stats.section.overview") {
                overviewRow(titleKey: "stats.total", value: "\(records.count)", symbol: "checkmark.circle")
                overviewRow(titleKey: "stats.totalTime", value: totalTimeFormatted, symbol: "clock")
            }

            Section("stats.section.sudoku") {
                ForEach(Difficulty.allCases) { difficulty in
                    difficultyRow(difficulty)
                }
            }

            if ticTacToeWins > 0 {
                Section("stats.section.tictactoe") {
                    overviewRow(titleKey: "stats.tictactoe.wins", value: "\(ticTacToeWins)", symbol: "trophy")
                }
            }
        }
    }

    private func overviewRow(titleKey: LocalizedStringKey, value: String, symbol: String) -> some View {
        LabeledContent {
            Text(value).font(.body.monospacedDigit())
        } label: {
            Label(titleKey, systemImage: symbol)
        }
    }

    private func difficultyRow(_ difficulty: Difficulty) -> some View {
        let matched = records.filter { $0.difficulty == difficulty && $0.gameType == .sudoku }
        let best = matched.map(\.durationSeconds).min()
        return HStack {
            Circle().fill(difficulty.color).frame(width: 10, height: 10)
            Text(difficulty.titleKey)
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("stats.count.\(matched.count)")
                    .font(.subheadline)
                if let best {
                    Text(GameRecord.format(seconds: best))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.yellow)
                }
            }
        }
    }

    // MARK: - 计算

    private var totalTimeFormatted: String {
        let total = records.reduce(0) { $0 + $1.durationSeconds }
        let h = total / 3600
        let m = (total % 3600) / 60
        return h > 0 ? "\(h)h \(m)m" : "\(m)m"
    }

    private var ticTacToeWins: Int {
        records.filter { $0.gameType == .ticTacToe }.count
    }
}

#Preview {
    StatsView()
        .modelContainer(for: GameRecord.self, inMemory: true)
}
