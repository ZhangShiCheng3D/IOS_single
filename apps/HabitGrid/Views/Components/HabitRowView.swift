//
//  HabitRowView.swift
//  HabitGrid
//
//  习惯列表行：图标 + 名称 + 连续天数 + 今日打卡按钮 + 迷你近 17 周热力图。
//

import SwiftUI

struct HabitRowView: View {
    let habit: Habit
    let stats: HabitStats
    let palette: ColorPalette
    let isCompletedToday: Bool
    let intensity: (Date) -> Int

    /// 点击今日打卡圆按钮。
    let onToggleToday: () -> Void

    @Environment(\.colorScheme) private var scheme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 顶部：图标 + 名称 + streak + 勾选
            HStack(spacing: 12) {
                iconBadge

                VStack(alignment: .leading, spacing: 3) {
                    Text(habit.name)
                        .font(.headline)
                        .lineLimit(1)
                    HStack(spacing: 8) {
                        StreakBadge(streak: stats.currentStreak, accent: habit.color)
                        Text("row.rate \(Int(stats.completionRate * 100))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer(minLength: 0)

                checkButton
            }

            // 迷你热力图（近 17 周），只读预览
            HeatmapView(
                intensity: intensity,
                palette: ColorPalette(
                    id: palette.id,
                    nameKey: palette.nameKey,
                    levels: levelsForHabit,
                    accentHex: habit.colorHex,
                    isPremium: palette.isPremium
                ),
                onTap: nil,
                weeks: 17,
                showsLabels: false,
                cellSize: 11,
                spacing: 2.5
            )
            .allowsHitTesting(false)
        }
        .padding(16)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .cardShadow()
    }

    private var iconBadge: some View {
        Image(systemName: habit.iconName)
            .font(.title3)
            .foregroundStyle(habit.color)
            .frame(width: 44, height: 44)
            .background(habit.color.opacity(0.15), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var checkButton: some View {
        Button(action: onToggleToday) {
            ZStack {
                Circle()
                    .fill(isCompletedToday ? habit.color : Color.clear)
                    .frame(width: 36, height: 36)
                Circle()
                    .strokeBorder(isCompletedToday ? habit.color : Color.secondary.opacity(0.4), lineWidth: 2)
                    .frame(width: 36, height: 36)
                if isCompletedToday {
                    Image(systemName: "checkmark")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                        .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isCompletedToday ? Text("a11y.uncheck") : Text("a11y.check"))
        .accessibilityValue(Text(habit.name))
    }

    /// 用习惯自身颜色构造一套同色系四级深浅，让每行热力图与习惯色一致且有层次。
    private var levelsForHabit: [String] {
        Color.heatLevels(fromHex: habit.colorHex)
    }
}

#Preview("Habit Row") {
    let habit = Habit(name: "每天阅读", iconName: "book.fill", colorHex: "#8B5CF6")
    return HabitRowView(
        habit: habit,
        stats: HabitStats(currentStreak: 7, longestStreak: 21, totalCompletions: 40, completionRate: 0.82, thisWeekCount: 5),
        palette: .default,
        isCompletedToday: true,
        intensity: { date in
            let day = Calendar.current.component(.day, from: date)
            return [0, 1, 0, 2, 0, 3, 1][day % 7]
        },
        onToggleToday: {}
    )
    .padding()
}
