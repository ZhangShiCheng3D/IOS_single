//
//  YearInPixelsView.swift
//  OneWord
//
//  A "year in pixels" grid: 12 month rows × up to 31 day cells, each tinted by
//  that day's mood. A compact, screenshot-friendly view of a whole year —
//  computed entirely on-device from the user's own entries.
//

import SwiftUI

struct YearInPixelsView: View {
    let entries: [DiaryEntry]
    let year: Int

    private let cell: CGFloat = 9
    private let gap: CGFloat = 2
    private let labelWidth: CGFloat = 24

    /// month (1...12) → day (1...31) → sentiment for that day.
    private var sentimentByMonthDay: [Int: [Int: Sentiment]] {
        var map: [Int: [Int: Sentiment]] = [:]
        let cal = Calendar.current
        for entry in entries {
            let c = cal.dateComponents([.month, .day], from: entry.date)
            guard let m = c.month, let d = c.day else { continue }
            map[m, default: [:]][d] = entry.sentiment
        }
        return map
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("year.pixels").font(.headline)

            ScrollView(.horizontal, showsIndicators: false) {
                VStack(alignment: .leading, spacing: gap) {
                    ForEach(1...12, id: \.self) { month in
                        HStack(spacing: gap) {
                            Text(monthSymbol(month))
                                .font(.system(size: 9))
                                .foregroundStyle(.secondary)
                                .frame(width: labelWidth, alignment: .leading)
                            ForEach(1...31, id: \.self) { day in
                                pixel(month: month, day: day)
                            }
                        }
                    }
                }
            }

            Text("year.pixelsFooter")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    @ViewBuilder
    private func pixel(month: Int, day: Int) -> some View {
        if day > daysIn(month: month) {
            Color.clear.frame(width: cell, height: cell)
        } else {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(sentimentByMonthDay[month]?[day]?.color ?? Theme.card)
                .frame(width: cell, height: cell)
        }
    }

    private func monthSymbol(_ month: Int) -> String {
        let symbols = Calendar.current.shortMonthSymbols
        return (month >= 1 && month <= symbols.count) ? symbols[month - 1] : "\(month)"
    }

    private func daysIn(month: Int) -> Int {
        var comps = DateComponents()
        comps.year = year
        comps.month = month
        let cal = Calendar.current
        guard let date = cal.date(from: comps),
              let range = cal.range(of: .day, in: .month, for: date) else { return 31 }
        return range.count
    }
}

#Preview {
    YearInPixelsView(entries: [], year: Calendar.current.component(.year, from: Date()))
        .padding()
}
