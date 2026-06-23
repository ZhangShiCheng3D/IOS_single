//
//  CalendarView.swift
//  OneWord
//
//  Month grid where each day is tinted by that day's mood. Tapping a day with
//  an entry opens it; tapping an empty past/today cell opens the editor.
//

import SwiftUI
import SwiftData

struct CalendarView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \DiaryEntry.date) private var entries: [DiaryEntry]

    @State private var month: Date = Date().startOfMonth
    @State private var editorDate: Date?
    @State private var detailEntry: DiaryEntry?

    /// Fast lookup of entry by start-of-day.
    private var entriesByDay: [Date: DiaryEntry] {
        Dictionary(entries.map { ($0.date, $0) }, uniquingKeysWith: { a, _ in a })
    }

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    monthSwitcher
                    weekdayHeader
                    grid
                    legend
                }
                .padding(Theme.Spacing.lg)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("tab.calendar")
            .sheet(item: $editorDate) { wrapper in
                EntryEditorView(date: wrapper, existing: entriesByDay[wrapper.startOfDay])
            }
            .navigationDestination(item: $detailEntry) { entry in
                EntryDetailView(entry: entry)
            }
        }
    }

    // MARK: Header

    private var monthSwitcher: some View {
        HStack {
            Button {
                withAnimation { month = month.addingMonths(-1) }
            } label: {
                Image(systemName: "chevron.left").font(.headline)
            }
            .accessibilityLabel("a11y.previousMonth")
            Spacer()
            Text(month.monthYearString)
                .font(.title3.bold())
            Spacer()
            Button {
                withAnimation { month = month.addingMonths(1) }
            } label: {
                Image(systemName: "chevron.right").font(.headline)
            }
            .accessibilityLabel("a11y.nextMonth")
            .disabled(month.addingMonths(1) > Date().startOfMonth)
            .opacity(month.addingMonths(1) > Date().startOfMonth ? 0.3 : 1)
        }
    }

    private var weekdayHeader: some View {
        let symbols = orderedWeekdaySymbols()
        return HStack {
            ForEach(symbols, id: \.self) { symbol in
                Text(symbol)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: Grid

    private var grid: some View {
        LazyVGrid(columns: columns, spacing: 6) {
            ForEach(Array(daysGrid().enumerated()), id: \.offset) { _, day in
                if let day {
                    dayCell(day)
                } else {
                    Color.clear.frame(height: 44)
                }
            }
        }
    }

    private func dayCell(_ day: Date) -> some View {
        let entry = entriesByDay[day.startOfDay]
        let isToday = day.isSameDay(as: Date())
        let isFuture = day.startOfDay > Date().startOfDay

        return Button {
            if let entry {
                detailEntry = entry
            } else if !isFuture {
                editorDate = day
            }
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous)
                    .fill(entry?.sentiment.color.opacity(0.85) ?? Theme.card)
                if let entry {
                    Text(entry.emoji).font(.title3)
                } else {
                    Text("\(Calendar.current.component(.day, from: day))")
                        .font(.callout)
                        .foregroundStyle(isFuture ? .tertiary : .secondary)
                }
            }
            .frame(height: 44)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous)
                    .strokeBorder(isToday ? Theme.accent : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .disabled(isFuture && entry == nil)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(dayAccessibilityLabel(day, entry: entry))
        .accessibilityAddTraits(.isButton)
    }

    /// Spoken description for a calendar day: the date plus that day's mood.
    private func dayAccessibilityLabel(_ day: Date, entry: DiaryEntry?) -> Text {
        if let entry {
            return Text(verbatim: "\(day.mediumString), \(entry.sentiment.localizedTitle)")
        }
        return Text(verbatim: day.mediumString)
    }

    private var legend: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("calendar.legend")
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack {
                ForEach(Sentiment.allCases) { sentiment in
                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(sentiment.color)
                            .frame(width: 28, height: 16)
                        Text(sentiment.title)
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .cardStyle()
    }

    // MARK: Date math

    /// Builds the month grid with leading nil padding for alignment.
    private func daysGrid() -> [Date?] {
        let calendar = Calendar.current
        let firstOfMonth = month.startOfMonth
        let leadingBlanks = firstOfMonth.localizedWeekdayIndex
        let dayCount = month.daysInMonth

        var cells: [Date?] = Array(repeating: nil, count: leadingBlanks)
        for offset in 0..<dayCount {
            cells.append(calendar.date(byAdding: .day, value: offset, to: firstOfMonth))
        }
        return cells
    }

    private func orderedWeekdaySymbols() -> [String] {
        let calendar = Calendar.current
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        let first = calendar.firstWeekday - 1
        return Array(symbols[first...] + symbols[..<first])
    }
}

// Allow `Date` to drive a `.sheet(item:)`.
extension Date: @retroactive Identifiable {
    public var id: TimeInterval { timeIntervalSince1970 }
}

#Preview {
    CalendarView()
        .modelContainer(PreviewData.container)
}
