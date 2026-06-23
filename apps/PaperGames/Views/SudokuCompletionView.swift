//
//  SudokuCompletionView.swift
//  PaperGames
//
//  数独完成结算弹窗。展示用时、错误数、是否破纪录，并提供再来一局/返回。
//

import SwiftUI

struct SudokuCompletionView: View {
    let difficulty: Difficulty
    let seconds: Int
    let mistakes: Int
    let isNewBest: Bool
    let onNewGame: () -> Void
    let onHome: () -> Void

    @State private var badgeScale: CGFloat = 0.5

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.15))
                    .frame(width: 88, height: 88)
                Image(systemName: "checkmark")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(.green)
            }
            .scaleEffect(badgeScale)
            .padding(.top, 8)
            .onAppear {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.55)) {
                    badgeScale = 1
                }
            }
            .accessibilityHidden(true)

            Text("sudoku.complete.title")
                .font(.title2.bold())

            if isNewBest {
                Label("sudoku.complete.newBest", systemImage: "trophy.fill")
                    .font(.headline)
                    .foregroundStyle(.yellow)
            }

            HStack(spacing: 24) {
                statBlock(titleKey: "sudoku.complete.time", value: GameRecord.format(seconds: seconds), symbol: "clock")
                statBlock(titleKey: "sudoku.complete.mistakes", value: "\(mistakes)", symbol: "xmark.circle")
            }

            Spacer(minLength: 0)

            VStack(spacing: 12) {
                Button(action: onNewGame) {
                    Text("sudoku.complete.newGame")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundStyle(.white)
                        .background(Color.appAccent.gradient, in: RoundedRectangle(cornerRadius: AppMetrics.cornerRadius, style: .continuous))
                }
                Button(action: onHome) {
                    Text("sudoku.complete.home")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
            }
        }
        .padding(24)
        .background(Color.appBackground.ignoresSafeArea())
    }

    private func statBlock(titleKey: LocalizedStringKey, value: String, symbol: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: symbol)
                .font(.title3)
                .foregroundStyle(Color.appAccent)
            Text(value)
                .font(.title3.bold().monospacedDigit())
            Text(titleKey)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.appSurface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

#Preview {
    SudokuCompletionView(
        difficulty: .hard,
        seconds: 372,
        mistakes: 2,
        isNewBest: true,
        onNewGame: {},
        onHome: {}
    )
}
