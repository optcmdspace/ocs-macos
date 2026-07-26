import Foundation

nonisolated struct ParsedDueDate: Sendable, Equatable {
    let body: String
    let dueAt: Date?
}

// A trailing natural-language date, anchored to `now`, consumed only when it isn't the whole text.
nonisolated enum DueDateParser {
    private static let maxPhraseTokens = 3

    static func parse(_ text: String, now: Date, calendar: Calendar = .current) -> ParsedDueDate {
        let tokens = text.split(whereSeparator: { $0.isWhitespace }).map(String.init)
        guard !tokens.isEmpty else { return ParsedDueDate(body: text, dueAt: nil) }
        let lowered = tokens.map { $0.lowercased() }
        guard let m = match(lowered, now: now, calendar: calendar) else {
            return ParsedDueDate(body: text, dueAt: nil)
        }
        // Refuse to consume the phrase if nothing meaningful is left to capture.
        guard tokens.count > m.length else { return ParsedDueDate(body: text, dueAt: nil) }
        let body = tokens.dropLast(m.length).joined(separator: " ")
        return ParsedDueDate(body: body, dueAt: m.date)
    }

    // Whole-string parse (not a trailing phrase) for the scheduling field, where the input is only a date.
    static func parseDirective(_ text: String, now: Date, calendar: Calendar = .current) -> Date? {
        let tokens = text.split(whereSeparator: { $0.isWhitespace }).map { $0.lowercased() }
        guard let m = match(tokens, now: now, calendar: calendar), m.length == tokens.count else { return nil }
        return m.date
    }

    // Trailing date run + resolved date; longest phrase first so "next monday" beats "monday".
    static func match(_ tokens: [String], now: Date, calendar: Calendar = .current) -> (length: Int, date: Date)? {
        guard !tokens.isEmpty else { return nil }
        for length in stride(from: min(maxPhraseTokens, tokens.count), through: 1, by: -1) {
            let phrase = Array(tokens.suffix(length))
            if let date = resolve(phrase, now: now, calendar: calendar) {
                return (length, date)
            }
        }
        return nil
    }

    private static func resolve(_ phrase: [String], now: Date, calendar: Calendar) -> Date? {
        let startOfToday = calendar.startOfDay(for: now)
        switch phrase.count {
        case 1: return singleWord(phrase[0], from: startOfToday, calendar: calendar)
        case 2: return twoWord(phrase[0], phrase[1], from: startOfToday, calendar: calendar)
        case 3: return relativeCount(phrase, from: startOfToday, calendar: calendar)
        default: return nil
        }
    }

    private static func singleWord(_ t: String, from startOfToday: Date, calendar: Calendar) -> Date? {
        switch t {
        case "today", "tdy", "tonight", "eod":
            return startOfToday
        case "tomorrow", "tmrw", "tmr", "tmw", "tm", "tomo":
            return calendar.date(byAdding: .day, value: 1, to: startOfToday)
        case "nw":
            return calendar.date(byAdding: .day, value: 7, to: startOfToday)
        case "tw", "eow":
            return endOfWeek(from: startOfToday, calendar: calendar)
        default:
            guard let wd = weekday(t) else { return nil }
            return nextOccurrence(of: wd, from: startOfToday, calendar: calendar)
        }
    }

    private static func twoWord(_ a: String, _ b: String, from startOfToday: Date, calendar: Calendar) -> Date? {
        switch (a, b) {
        case ("next", "week"):
            return calendar.date(byAdding: .day, value: 7, to: startOfToday)
        case ("this", "week"):
            return endOfWeek(from: startOfToday, calendar: calendar)
        case ("next", _):
            guard let wd = weekday(b),
                  let base = nextOccurrence(of: wd, from: startOfToday, calendar: calendar) else { return nil }
            return calendar.date(byAdding: .day, value: 7, to: base)
        case ("this", _):
            guard let wd = weekday(b) else { return nil }
            return nextOccurrence(of: wd, from: startOfToday, calendar: calendar)
        default:
            return monthDay(a, b, from: startOfToday, calendar: calendar)
        }
    }

    // "jul 12" / "july 12" -> the upcoming occurrence (next year if it already passed this year).
    private static func monthDay(_ monthToken: String, _ dayToken: String, from startOfToday: Date, calendar: Calendar) -> Date? {
        guard let month = month(monthToken), let day = dayNumber(dayToken) else { return nil }
        var comps = DateComponents()
        comps.year = calendar.component(.year, from: startOfToday)
        comps.month = month
        comps.day = day
        // Reject impossible dates (e.g. "feb 30") that the calendar would otherwise roll forward.
        guard let candidate = calendar.date(from: comps),
              calendar.component(.month, from: candidate) == month,
              calendar.component(.day, from: candidate) == day else { return nil }
        let start = calendar.startOfDay(for: candidate)
        guard start < startOfToday else { return start }
        return calendar.date(byAdding: .year, value: 1, to: start)
    }

    private static func month(_ token: String) -> Int? {
        switch token {
        case "january", "jan": return 1
        case "february", "feb": return 2
        case "march", "mar": return 3
        case "april", "apr": return 4
        case "may": return 5
        case "june", "jun": return 6
        case "july", "jul": return 7
        case "august", "aug": return 8
        case "september", "sep", "sept": return 9
        case "october", "oct": return 10
        case "november", "nov": return 11
        case "december", "dec": return 12
        default: return nil
        }
    }

    // Leading digits of the token, tolerating an ordinal suffix ("12th" -> 12), within a valid day range.
    private static func dayNumber(_ token: String) -> Int? {
        let digits = token.prefix(while: { $0.isNumber })
        guard let n = Int(digits), (1...31).contains(n) else { return nil }
        return n
    }

    private static func relativeCount(_ phrase: [String], from startOfToday: Date, calendar: Calendar) -> Date? {
        guard phrase[0] == "in", let n = numberValue(phrase[1]) else { return nil }
        let days: Int
        switch phrase[2] {
        case "day", "days": days = n
        case "week", "weeks": days = n * 7
        default: return nil
        }
        return calendar.date(byAdding: .day, value: days, to: startOfToday)
    }

    private static func endOfWeek(from startOfToday: Date, calendar: Calendar) -> Date? {
        // interval.end is 00:00 of next week's first day; back up one day for the last day of this week.
        guard let interval = calendar.dateInterval(of: .weekOfYear, for: startOfToday) else { return nil }
        return calendar.date(byAdding: .day, value: -1, to: interval.end)
    }

    // The next date strictly after today that lands on `weekday` (1 = Sunday ... 7 = Saturday).
    private static func nextOccurrence(of weekday: Int, from startOfToday: Date, calendar: Calendar) -> Date? {
        let todayWeekday = calendar.component(.weekday, from: startOfToday)
        var delta = (weekday - todayWeekday + 7) % 7
        if delta == 0 { delta = 7 }
        return calendar.date(byAdding: .day, value: delta, to: startOfToday)
    }

    private static func weekday(_ token: String) -> Int? {
        switch token {
        case "sunday", "sun": return 1
        case "monday", "mon": return 2
        case "tuesday", "tue", "tues": return 3
        case "wednesday", "wed", "weds": return 4
        case "thursday", "thu", "thur", "thurs": return 5
        case "friday", "fri": return 6
        case "saturday", "sat": return 7
        default: return nil
        }
    }

    private static func numberValue(_ token: String) -> Int? {
        if let n = Int(token), n >= 0 { return n }
        switch token {
        case "a", "an", "one": return 1
        case "two": return 2
        case "three": return 3
        case "four": return 4
        case "five": return 5
        case "six": return 6
        case "seven": return 7
        case "eight": return 8
        case "nine": return 9
        case "ten": return 10
        default: return nil
        }
    }
}
