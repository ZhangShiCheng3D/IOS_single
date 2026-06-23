//
//  AchievementsView.swift
//  LumenPuzzle
//
//  成就墙。已解锁成就点亮金色，未解锁显示为剪影。
//

import SwiftUI
import SwiftData

struct AchievementsView: View {

    @Environment(\.modelContext) private var modelContext

    /// 已解锁成就集合（出现时刷新）。
    @State private var unlocked: Set<Achievement> = []

    var body: some View {
        ZStack {
            LinearGradient.lumenBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 14) {
                    progressHeader

                    ForEach(Achievement.allCases) { achievement in
                        row(for: achievement, isUnlocked: unlocked.contains(achievement))
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle(Text("achievements.title"))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: refresh)
    }

    private func refresh() {
        unlocked = ProgressService(context: modelContext).unlockedAchievements()
    }

    private var progressHeader: some View {
        let total = Achievement.allCases.count
        let count = unlocked.count
        return VStack(spacing: 8) {
            Text("\(count)/\(total)")
                .font(.system(size: 40, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.lumenAccent)
            ProgressView(value: Double(count), total: Double(total))
                .tint(Color.lumenAccent)
            Text("achievements.subtitle")
                .font(.caption)
                .foregroundStyle(Color.lumenTextSecondary)
        }
        .padding(.bottom, 8)
    }

    private func row(for achievement: Achievement, isUnlocked: Bool) -> some View {
        HStack(spacing: 16) {
            Image(systemName: achievement.symbolName)
                .font(.title2)
                .foregroundStyle(isUnlocked ? Color.lumenAccent : Color.lumenTextSecondary.opacity(0.5))
                .frame(width: 48, height: 48)
                .background(
                    Circle().fill(Color.lumenSurface.opacity(isUnlocked ? 0.6 : 0.3))
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(achievement.titleKey.asLocalizedKey)
                    .font(.headline)
                    .foregroundStyle(isUnlocked ? Color.lumenText : Color.lumenTextSecondary)
                Text(achievement.detailKey.asLocalizedKey)
                    .font(.caption)
                    .foregroundStyle(Color.lumenTextSecondary)
            }

            Spacer()

            if isUnlocked {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(Color.lumenAccent)
            } else {
                Image(systemName: "lock.fill")
                    .foregroundStyle(Color.lumenTextSecondary.opacity(0.5))
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.lumenSurface.opacity(0.35))
        )
        .opacity(isUnlocked ? 1 : 0.7)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    NavigationStack {
        AchievementsView()
            .modelContainer(for: [LevelProgress.self, AchievementRecord.self], inMemory: true)
    }
}
