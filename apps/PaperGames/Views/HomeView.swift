//
//  HomeView.swift
//  PaperGames
//
//  游戏选择主页。卡片式展示所有玩法，付费玩法显示锁标记。
//

import SwiftUI

struct HomeView: View {
    @Environment(PurchaseManager.self) private var store
    @State private var showPaywall = false

    private let columns = [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    heroBanner

                    Text("home.section.games")
                        .font(.title3.bold())
                        .padding(.horizontal)

                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(GameType.allCases) { game in
                            gameCard(game)
                        }
                    }
                    .padding(.horizontal)

                    if !store.isUnlocked {
                        upgradeBanner
                            .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle(Text("home.title"))
            .navigationDestination(for: GameType.self) { game in
                destination(for: game)
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }

    // MARK: - 顶部横幅

    private var heroBanner: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("home.hero.title")
                .font(.largeTitle.bold())
            Text("home.hero.subtitle")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.appAccent.opacity(0.12))
        )
        .padding(.horizontal)
    }

    // MARK: - 游戏卡片

    @ViewBuilder
    private func gameCard(_ game: GameType) -> some View {
        let locked = !store.canPlay(game)
        Group {
            if locked {
                Button {
                    showPaywall = true
                } label: {
                    cardContent(game, locked: true)
                }
                .buttonStyle(.pressable)
            } else {
                NavigationLink(value: game) {
                    cardContent(game, locked: false)
                }
                .buttonStyle(.pressable)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(game.titleKey)
        .accessibilityHint(Text(locked ? "a11y.locked.hint" : "a11y.game.hint"))
    }

    private func cardContent(_ game: GameType, locked: Bool) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: game.symbol)
                    .font(.system(size: 30))
                    .foregroundStyle(game.accent)
                Spacer()
                if locked {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 8)
            Text(game.titleKey)
                .font(.headline)
                .foregroundStyle(.primary)
            Text(game.subtitleKey)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, minHeight: 150, alignment: .leading)
        .padding(AppMetrics.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: AppMetrics.cornerRadius, style: .continuous)
                .fill(Color.appSurface)
                .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppMetrics.cornerRadius, style: .continuous)
                .strokeBorder(game.accent.opacity(0.15), lineWidth: 1)
        )
    }

    // MARK: - 升级横幅

    private var upgradeBanner: some View {
        Button {
            showPaywall = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "crown.fill")
                    .font(.title2)
                    .foregroundStyle(.yellow)
                VStack(alignment: .leading, spacing: 2) {
                    Text("home.upgrade.title")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text("home.upgrade.subtitle")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.85))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.white.opacity(0.8))
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: AppMetrics.cornerRadius, style: .continuous)
                    .fill(LinearGradient(colors: [.appAccent, .appSecondary], startPoint: .leading, endPoint: .trailing))
            )
        }
        .buttonStyle(.pressable)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("home.upgrade.title"))
        .accessibilityHint(Text("home.upgrade.subtitle"))
    }

    // MARK: - 路由

    @ViewBuilder
    private func destination(for game: GameType) -> some View {
        switch game {
        case .sudoku:
            DifficultySelectionView()
        case .ticTacToe:
            TicTacToeView()
        }
    }
}

#Preview {
    HomeView()
        .environment(PurchaseManager())
        .environment(SettingsStore())
        .modelContainer(for: GameRecord.self, inMemory: true)
}
