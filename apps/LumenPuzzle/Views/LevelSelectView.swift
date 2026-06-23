//
//  LevelSelectView.swift
//  LumenPuzzle
//
//  关卡选择。网格展示 10 关，区分三种状态：
//   · 可游玩（免费关或前序已通关 + 已购买）
//   · 进度未解锁（需先通关前一关）
//   · 付费锁定（超出免费关且未购买）
//

import SwiftUI
import SwiftData

struct LevelSelectView: View {

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var purchaseManager: PurchaseManager

    /// 是否展示付费墙。
    @State private var showPaywall = false

    private let columns = [GridItem(.adaptive(minimum: 96, maximum: 140), spacing: 16)]

    var body: some View {
        ZStack {
            LinearGradient.lumenBackground.ignoresSafeArea()

            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(LevelCatalog.all) { level in
                        cell(for: level)
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle(Text("levelselect.title"))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showPaywall) {
            PaywallView()
                .environmentObject(purchaseManager)
        }
    }

    // MARK: - 单元格

    @ViewBuilder
    private func cell(for level: Level) -> some View {
        let service = ProgressService(context: modelContext)
        let progressUnlocked = service.isUnlocked(level.id)
        let purchaseLocked = purchaseManager.isLocked(levelID: level.id)
        let completed = service.isCompleted(level.id)

        if purchaseLocked {
            // 付费锁定：点击拉起付费墙。
            Button {
                Haptics.selection()
                showPaywall = true
            } label: {
                LevelCell(level: level, state: .paywallLocked, completed: false)
            }
            .buttonStyle(.plain)
        } else if progressUnlocked {
            NavigationLink(value: ContentView.Route.game(level.id)) {
                LevelCell(level: level, state: .unlocked, completed: completed)
            }
            .buttonStyle(.plain)
            .simultaneousGesture(TapGesture().onEnded { Haptics.selection() })
        } else {
            // 进度未解锁：不可点击。
            LevelCell(level: level, state: .progressLocked, completed: false)
        }
    }
}

/// 关卡单元格视图。
private struct LevelCell: View {

    enum State {
        case unlocked
        case progressLocked
        case paywallLocked
    }

    let level: Level
    let state: State
    let completed: Bool

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.lumenSurface.opacity(state == .unlocked ? 0.55 : 0.28))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(difficultyColor.opacity(state == .unlocked ? 0.7 : 0.25), lineWidth: 1.5)
                    )
                    .frame(height: 96)

                content
            }

            Text(level.nameKey.asLocalizedKey)
                .font(.caption)
                .foregroundStyle(state == .unlocked ? Color.lumenText : Color.lumenTextSecondary)
                .lineLimit(1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    @ViewBuilder
    private var content: some View {
        switch state {
        case .unlocked:
            VStack(spacing: 6) {
                Text("\(level.id)")
                    .font(.system(size: 30, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.lumenText)
                if completed {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.caption)
                        .foregroundStyle(Color.lumenAccent)
                }
            }
        case .progressLocked:
            Image(systemName: "lock.fill")
                .font(.title2)
                .foregroundStyle(Color.lumenTextSecondary)
        case .paywallLocked:
            VStack(spacing: 6) {
                Image(systemName: "cart.fill")
                    .font(.title3)
                    .foregroundStyle(Color.lumenAccent)
                Text("levelselect.unlock")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Color.lumenTextSecondary)
            }
        }
    }

    private var difficultyColor: Color {
        switch level.difficulty {
        case .easy:   return .green
        case .medium: return .orange
        case .hard:   return .pink
        }
    }

    private var accessibilityLabel: Text {
        switch state {
        case .unlocked:
            return completed
                ? Text("a11y.level.completed \(level.id)")
                : Text("a11y.level.unlocked \(level.id)")
        case .progressLocked:
            return Text("a11y.level.locked \(level.id)")
        case .paywallLocked:
            return Text("a11y.level.paywall \(level.id)")
        }
    }
}

#Preview {
    NavigationStack {
        LevelSelectView()
            .environmentObject(PurchaseManager())
            .modelContainer(for: [LevelProgress.self, AchievementRecord.self], inMemory: true)
    }
}
