//
//  TicTacToeView.swift
//  PaperGames
//
//  井字棋界面。玩家执 ✕，挑战不败 AI（○）。含比分与胜利连线高亮。
//

import SwiftUI
import SwiftData

struct TicTacToeView: View {
    @State private var viewModel = TicTacToeViewModel()
    @Environment(\.modelContext) private var modelContext

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)

    var body: some View {
        VStack(spacing: 24) {
            scoreboard

            statusText

            board

            Button {
                viewModel.reset()
            } label: {
                Label("tictactoe.newRound", systemImage: "arrow.clockwise")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .foregroundStyle(.white)
                    .background(Color.appAccent.gradient, in: RoundedRectangle(cornerRadius: AppMetrics.cornerRadius, style: .continuous))
            }
            .padding(.horizontal)

            Spacer()
        }
        .padding(.top)
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle(Text("game.tictactoe.title"))
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: viewModel.outcome) { _, outcome in
            // 仅在玩家战胜不败 AI 时记录一场胜利，供统计页展示。
            if outcome == .win(.x) {
                let record = GameRecord(gameType: .ticTacToe, durationSeconds: 0)
                modelContext.insert(record)
                try? modelContext.save()
            }
        }
    }

    // MARK: - 比分

    private var scoreboard: some View {
        HStack {
            scoreBlock(titleKey: "tictactoe.you", value: viewModel.playerWins, color: .appAccent)
            scoreBlock(titleKey: "tictactoe.draws", value: viewModel.draws, color: .secondary)
            scoreBlock(titleKey: "tictactoe.ai", value: viewModel.aiWins, color: .appSecondary)
        }
        .padding(.horizontal)
    }

    private func scoreBlock(titleKey: LocalizedStringKey, value: Int, color: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.title.bold().monospacedDigit())
                .foregroundStyle(color)
            Text(titleKey)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.appSurface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: - 状态文字

    private var statusText: some View {
        Group {
            switch viewModel.outcome {
            case .ongoing:
                Text(viewModel.isThinking ? "tictactoe.aiTurn" : "tictactoe.yourTurn")
            case .win(let mark):
                Text(mark == .x ? "tictactoe.youWin" : "tictactoe.aiWin")
            case .draw:
                Text("tictactoe.draw")
            }
        }
        .font(.headline)
        .foregroundStyle(.primary)
    }

    // MARK: - 棋盘

    private var board: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(0..<9, id: \.self) { index in
                cell(index)
            }
        }
        .padding(.horizontal, 40)
        .animation(.spring(response: 0.35, dampingFraction: 0.65), value: viewModel.board)
        .animation(.easeOut(duration: 0.25), value: viewModel.winningLine)
    }

    private func cell(_ index: Int) -> some View {
        let mark = viewModel.board[index]
        let isWinning = viewModel.winningLine?.contains(index) ?? false
        return Button {
            viewModel.playerMove(at: index)
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isWinning ? Color.green.opacity(0.25) : Color.appSurface)
                if let mark {
                    Text(mark.rawValue)
                        .font(.system(size: 52, weight: .bold, design: .rounded))
                        .foregroundStyle(mark == .x ? Color.appAccent : Color.appSecondary)
                        .transition(.scale(scale: 0.4).combined(with: .opacity))
                }
            }
            .aspectRatio(1, contentMode: .fit)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.pressable)
        .disabled(mark != nil || viewModel.outcome != .ongoing)
        .accessibilityLabel(cellAccessibilityLabel(index, mark: mark))
        .accessibilityAddTraits(mark == nil ? .isButton : [])
    }

    /// 棋格 VoiceOver 描述：位置 + 占用方（你 / 电脑 / 空）。
    private func cellAccessibilityLabel(_ index: Int, mark: TicTacToeViewModel.Mark?) -> Text {
        let position = Text("a11y.cell.position.\(index / 3 + 1).\(index % 3 + 1)")
        switch mark {
        case .x: return position + Text(", ") + Text("tictactoe.you")
        case .o: return position + Text(", ") + Text("tictactoe.ai")
        case nil: return position + Text(", ") + Text("a11y.cell.empty")
        }
    }
}

#Preview {
    NavigationStack {
        TicTacToeView()
    }
    .modelContainer(for: GameRecord.self, inMemory: true)
}
