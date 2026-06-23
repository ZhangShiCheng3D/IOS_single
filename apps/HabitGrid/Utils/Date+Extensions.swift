//
//  Date+Extensions.swift
//  HabitGrid
//
//  日期工具：归一化、热力图日历构建、连续天数计算。
//

import Foundation

extension Date {
    /// 当天 00:00（本地时区）。
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    /// 与另一日期是否为同一天。
    func isSameDay(as other: Date, calendar: Calendar = .current) -> Bool {
        calendar.isDate(self, inSameDayAs: other)
    }

    /// 偏移 n 天后的日期。
    func adding(days: Int, calendar: Calendar = .current) -> Date {
        calendar.date(byAdding: .day, value: days, to: self) ?? self
    }
}

/// 热力图日历布局工具（GitHub 风格：列=周，行=星期）。
enum HeatmapCalendar {

    /// 默认展示的总周数（52 周 ≈ 一年）。
    static let weekCount = 53

    /// 构建热力图所需的日期网格。
    ///
    /// 返回值是按“周”分组的二维数组：`grid[week][weekdayIndex]`。
    /// 每周从周日开始（与 GitHub 一致），weekdayIndex 0 = 周日 ... 6 = 周六。
    /// 网格末列对齐到包含 `referenceDate` 的那一周。
    /// - Parameter weeks: 展示的周数。
    static func buildGrid(
        endingOn referenceDate: Date = .now,
        weeks: Int = weekCount,
        calendar: Calendar = .current
    ) -> [[Date]] {
        let today = calendar.startOfDay(for: referenceDate)

        // 找到“本周日”（包含 today 的那一周的第一天）。
        let weekdayOfToday = calendar.component(.weekday, from: today) // 1 = 周日
        guard let thisSunday = calendar.date(byAdding: .day, value: -(weekdayOfToday - 1), to: today) else {
            return []
        }

        // 网格起点：往前推 (weeks - 1) 周。
        guard let startSunday = calendar.date(byAdding: .day, value: -7 * (weeks - 1), to: thisSunday) else {
            return []
        }

        var grid: [[Date]] = []
        grid.reserveCapacity(weeks)
        for week in 0..<weeks {
            var column: [Date] = []
            column.reserveCapacity(7)
            for weekday in 0..<7 {
                let offset = week * 7 + weekday
                let date = calendar.date(byAdding: .day, value: offset, to: startSunday) ?? startSunday
                column.append(calendar.startOfDay(for: date))
            }
            grid.append(column)
        }
        return grid
    }

    /// 返回网格中每列对应的“月份标签”（仅在月份首次出现的列显示）。
    /// 返回数组与周列一一对应，无标签处为 nil。
    static func monthLabels(for grid: [[Date]], calendar: Calendar = .current) -> [String?] {
        var labels: [String?] = []
        var lastMonth = -1
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.setLocalizedDateFormatFromTemplate("MMM")

        for column in grid {
            // 用每列首日（周日）判定月份。
            guard let first = column.first else { labels.append(nil); continue }
            let month = calendar.component(.month, from: first)
            if month != lastMonth {
                lastMonth = month
                labels.append(formatter.string(from: first))
            } else {
                labels.append(nil)
            }
        }
        return labels
    }
}
