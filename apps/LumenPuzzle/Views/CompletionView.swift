//
//  CompletionView.swift
//  LumenPuzzle
//
//  通关结算面板。展示成绩、新解锁成就，并提供重玩 / 下一关 / 返回。
//

import SwiftUI

struct CompletionView: View {

    @EnvironmentObject private var purchaseManager: PurchaseManager

    let level: Level
    let timeText: String
    let moves: Int
    let newAchievements: [Achievement]
    let onReplay: () -> Void
    let onExit: () -> Void

    @State private var appear = false
    @State private var showPaywall = false

    /// 下一关（若存在）。
    private var nextLevel: Level? { LevelCatalog.level(id: level.id + 1) }

    var body: some View {
        ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()

            VStack(spacing: 22) {
                // 庆祝光环。
                Image(systemName: "sun.max.fill")
                    .font(.system(size: 60, weight: .light))
                    .foregroundStyle(Color.lumenAccent)
                    .shadow(color: Color.lumenAccent.opacity(0.7), radius: 24)
                    .scaleEffect(appear ? 1 : 0.4)
                    .rotationEffect(.degrees(appear ? 0 : -30))
                    .accessibilityHidden(true)

                Text("completion.title")
                    .font(.title.weight(.semibold))
                    .foregroundStyle(Color.lumenText)

                // 成绩。
                HStack(spacing: 28) {
                    stat(titleKey: "completion.time", value: timeText, icon: "clock")
                    stat(titleKey: "completion.moves", value: "\(moves)", icon: "hand.draw")
                }

                // 新成就。
                if !newAchievements.isEmpty {
                    VStack(spacing: 8) {
                        Text("completion.newachievements")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.lumenTextSecondary)
                        ForEach(newAchievements) { achievement in
                            HStack(spacing: 8) {
                                Image(systemName: achievement.symbolName)
                                    .foregroundStyle(Color.lumenAccent)
                                Text(achievement.titleKey.asLocalizedKey)
                                    .font(.subheadline)
                                    .foregroundStyle(Color.lumenText)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(Color.lumenSurface.opacity(0.6)))
                        }
                    }
                    .transition(.scale.combined(with: .opacity))
                }

                buttons
            }
            .padding(28)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            .padding(.horizontal, 32)
            .scaleEffect(appear ? 1 : 0.85)
            .opacity(appear ? 1 : 0)
        }
        .onAppear {
            withAnimation(Motion.panel) { appear = true }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView().environmentObject(purchaseManager)
        }
    }

    // MARK: - 组件

    private func stat(titleKey: LocalizedStringKey, value: String, icon: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color.lumenAccent)
            Text(value)
                .font(.title3.monospacedDigit().weight(.semibold))
                .foregroundStyle(Color.lumenText)
            Text(titleKey)
                .font(.caption2)
                .foregroundStyle(Color.lumenTextSecondary)
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var buttons: some View {
        VStack(spacing: 12) {
            if let next = nextLevel {
                if purchaseManager.canPlay(levelID: next.id) {
                    NavigationLink(value: ContentView.Route.game(next.id)) {
                        primaryLabel(titleKey: "completion.next", icon: "arrow.right")
                    }
                    .simultaneousGesture(TapGesture().onEnded { Haptics.selection() })
                } else {
                    // 下一关需购买。
                    Button {
                        Haptics.selection()
                        showPaywall = true
                    } label: {
                        primaryLabel(titleKey: "completion.unlocknext", icon: "lock.open")
                    }
                }
            }

            HStack(spacing: 12) {
                Button(action: { Haptics.selection(); onReplay() }) {
                    secondaryLabel(titleKey: "completion.replay", icon: "arrow.counterclockwise")
                }
                Button(action: { Haptics.selection(); onExit() }) {
                    secondaryLabel(titleKey: "completion.levels", icon: "square.grid.2x2")
                }
            }
        }
    }

    private func primaryLabel(titleKey: LocalizedStringKey, icon: String) -> some View {
        HStack {
            Text(titleKey).font(.headline)
            Image(systemName: icon)
        }
        .foregroundStyle(Color.black)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.lumenAccent))
        .lumenAccentShadow()
    }

    private func secondaryLabel(titleKey: LocalizedStringKey, icon: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
            Text(titleKey).font(.caption)
        }
        .foregroundStyle(Color.lumenText)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.lumenSurface.opacity(0.6)))
    }
}

#Preview {
    NavigationStack {
        CompletionView(
            level: LevelCatalog.level1,
            timeText: "00:18",
            moves: 3,
            newAchievements: [.firstLight, .swiftSolver],
            onReplay: {},
            onExit: {}
        )
        .environmentObject(PurchaseManager())
    }
}
