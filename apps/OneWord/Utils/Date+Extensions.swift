//
//  Date+Extensions.swift
//  OneWord
//
//  Calendar helpers used by the calendar grid, trends, and year review.
//

import Foundation

extension Date {

    /// Local midnight for this date.
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    /// First moment of this date's month.
    var startOfMonth: Date {
        let comps = Calendar.current.dateComponents([.year, .month], from: self)
        return Calendar.current.date(from: comps) ?? self
    }

    /// First moment of this date's year.
    var startOfYear: Date {
        let comps = Calendar.current.dateComponents([.year], from: self)
        return Calendar.current.date(from: comps) ?? self
    }

    /// Whether two dates fall on the same calendar day.
    func isSameDay(as other: Date) -> Bool {
        Calendar.current.isDate(self, inSameDayAs: other)
    }

    /// Number of days in this date's month.
    var daysInMonth: Int {
        Calendar.current.range(of: .day, in: .month, for: self)?.count ?? 30
    }

    /// Adds (or subtracts) calendar months.
    func addingMonths(_ months: Int) -> Date {
        Calendar.current.date(byAdding: .month, value: months, to: self) ?? self
    }

    /// Adds (or subtracts) calendar days.
    func addingDays(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: self) ?? self
    }

    /// The weekday index (0 = first weekday per the user's locale).
    var localizedWeekdayIndex: Int {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: self)
        return (weekday - calendar.firstWeekday + 7) % 7
    }
}

// MARK: - Formatting

extension Date {
    static let mediumDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()

    static let monthYearFormatter: DateFormatter = {
        let f = DateFormatter()
        f.setLocalizedDateFormatFromTemplate("yMMMM")
        return f
    }()

    static let weekdayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.setLocalizedDateFormatFromTemplate("EEEE")
        return f
    }()

    var mediumString: String { Self.mediumDateFormatter.string(from: self) }
    var monthYearString: String { Self.monthYearFormatter.string(from: self) }
    var weekdayString: String { Self.weekdayFormatter.string(from: self) }
}
