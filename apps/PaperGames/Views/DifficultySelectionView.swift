//
//  DifficultySelectionView.swift
//  PaperGames
//
//  数独难度选择页。免费难度可直接进入，付费难度显示锁并触发付费墙。
//

import SwiftUI

struct DifficultySelectionView: View {
    @Environment(PurchaseManager.self) private var store
    @State private var showPaywall = false
    @State private var selectedDifficulty: Difficulty?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(Difficulty.allCases) { difficulty in
                    difficultyRow(difficulty)
                }
            }
            .padding()
        }
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle(Text("game.sudoku.title"))
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showPaywall) { PaywallView() }
        .navigationDestination(item: $selectedDifficulty) { difficulty in
            SudokuGameView(difficulty: difficulty)
        }
    }

    @ViewBuilder
    private func difficultyRow(_ difficulty: Difficulty) -> some View {
        let locked = !store.canPlay(difficulty)
        Button {
            if locked {
                showPaywall = true
            } else {
                selectedDifficulty = difficulty
            }
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(difficulty.color.opacity(0.15))
                        .frame(width: 52, height: 52)
                    Image(systemName: locked ? "lock.fill" : "square.grid.3x3.fill")
                        .font(.title3)
                        .foregroundStyle(difficulty.color)
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text(difficulty.titleKey)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    // 难度强度条。
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.secondary.opacity(0.15))
                            Capsule()
                                .fill(difficulty.color)
                                .frame(width: geo.size.width * difficulty.intensity)
                        }
                    }
                    .frame(height: 6)
                }
                Spacer()
                Image(systemName: locked ? "lock.fill" : "chevron.right")
                    .foregroundStyle(.secondary)
            }
            .padding(AppMetrics.cardPadding)
            .cardSurface()
        }
        .buttonStyle(.pressable)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(difficulty.titleKey)
        .accessibilityHint(Text(locked ? "a11y.locked.hint" : "a11y.difficulty.hint"))
    }
}

#Preview {
    NavigationStack {
        DifficultySelectionView()
            .environment(PurchaseManager())
            .environment(SettingsStore())
            .modelContainer(for: GameRecord.self, inMemory: true)
    }
}
