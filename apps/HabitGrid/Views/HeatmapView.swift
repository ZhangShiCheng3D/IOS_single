//
//  HeatmapView.swift
//  HabitGrid
//
//  GitHub 风格习惯热力图（列=周，行=星期）。核心视觉组件。
//

import SwiftUI

/// 可滚动、可点击的热力图。
struct HeatmapView: View {

    /// 该习惯的打卡强度查询闭包：给定日期返回 0...4。
    let intensity: (Date) -> Int

    /// 配色方案。
    let palette: ColorPalette

    /// 点击某天的回调（nil 表示只读不可点）。
    var onTap: ((Date) -> Void)?

    /// 展示周数。
    var weeks: Int = HeatmapCalendar.weekCount

    /// 是否显示月份/星期标签。
    var showsLabels: Bool = true

    /// 单元格边长。
    var cellSize: CGFloat = 13

    /// 单元格间距。
    var spacing: CGFloat = 3

    @Environment(\.colorScheme) private var scheme

    private var grid: [[Date]] {
        HeatmapCalendar.buildGrid(weeks: weeks)
    }

    /// 星期标签：仅在第 1/3/5 行（周一/周三/周五）显示，与 GitHub 一致。
    /// 取系统本地化的极简星期符号（index 0 = 周日）。
    private var weekdaySymbols: [String] {
        let symbols = Calendar.current.veryShortStandaloneWeekdaySymbols
        guard symbols.count == 7 else { return Array(repeating: "", count: 7) }
        return (0..<7).map { ($0 % 2 == 1) ? symbols[$0] : "" }
    }

    var body: some View {
        let columns = grid
        let monthLabels = showsLabels ? HeatmapCalendar.monthLabels(for: columns) : []

        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 4) {
                    if showsLabels {
                        monthLabelRow(monthLabels)
                    }
                    HStack(alignment: .top, spacing: spacing) {
                        if showsLabels {
                            weekdayLabelColumn
                        }
                        ForEach(Array(columns.enumerated()), id: \.offset) { colIndex, week in
                            weekColumn(week)
                                .id(colIndex)
                        }
                    }
                }
                .padding(.vertical, 2)
            }
            .onAppear {
                // 默认滚动到最近一周。
                proxy.scrollTo(columns.count - 1, anchor: .trailing)
            }
        }
    }

    // MARK: - 列（一周）

    private func weekColumn(_ week: [Date]) -> some View {
        VStack(spacing: spacing) {
            ForEach(week, id: \.self) { day in
                cell(for: day)
            }
        }
    }

    private func cell(for day: Date) -> some View {
        let level = intensity(day)
        let isFuture = day > Date.now.startOfDay
        let isToday = day.isSameDay(as: .now)

        return RoundedRectangle(cornerRadius: 3, style: .continuous)
            .fill(isFuture ? Color.clear : palette.heatColor(intensity: level, scheme: scheme))
            .frame(width: cellSize, height: cellSize)
            .overlay {
                if isToday {
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .strokeBorder(palette.accent, lineWidth: 1.5)
                }
            }
            .opacity(isFuture ? 0.0 : 1.0)
            .contentShape(Rectangle())
            .onTapGesture {
                guard !isFuture, let onTap else { return }
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    onTap(day)
                }
            }
            .accessibilityLabel(accessibilityText(for: day, level: level))
            .accessibilityAddTraits(onTap != nil && !isFuture ? .isButton : [])
    }

    // MARK: - 标签

    private func monthLabelRow(_ labels: [String?]) -> some View {
        HStack(spacing: spacing) {
            if showsLabels {
                // 与星期标签列对齐的占位。
                Color.clear.frame(width: 16)
            }
            ForEach(Array(labels.enumerated()), id: \.offset) { _, label in
                Text(label ?? "")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
                    .frame(width: cellSize, alignment: .leading)
            }
        }
    }

    private var weekdayLabelColumn: some View {
        VStack(spacing: spacing) {
            ForEach(0..<7, id: \.self) { index in
                Text(weekdaySymbols[index])
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
                    .frame(width: 16, height: cellSize, alignment: .leading)
            }
        }
    }

    private func accessibilityText(for day: Date, level: Int) -> Text {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        let dateStr = formatter.string(from: day)
        let status = level > 0
            ? String(localized: "a11y.completed")
            : String(localized: "a11y.notCompleted")
        return Text("\(dateStr), \(status)")
    }
}

/// 热力图浓度图例（少 → 多）。
struct HeatmapLegend: View {
    let palette: ColorPalette
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        HStack(spacing: 4) {
            Text("heatmap.less")
                .font(.caption2)
                .foregroundStyle(.secondary)
            ForEach(0...4, id: \.self) { level in
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(palette.heatColor(intensity: level, scheme: scheme))
                    .frame(width: 11, height: 11)
            }
            Text("heatmap.more")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview("Heatmap") {
    // 用确定性伪随机数据演示。
    let palette = ColorPalette.default
    return VStack(spacing: 16) {
        HeatmapView(
            intensity: { date in
                let day = Calendar.current.component(.day, from: date)
                return [0, 0, 1, 2, 0, 3, 4, 1][day % 8]
            },
            palette: palette,
            onTap: { _ in }
        )
        HeatmapLegend(palette: palette)
    }
    .padding()
}
