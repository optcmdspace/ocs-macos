import Foundation

// Time-horizon grouping for the agenda view. Boundaries mirror CaptureRows.dueStamp so a row's stamp
// and its section never disagree (weekday names cover 1..6 days out; "later" starts at a week).
nonisolated enum DueBucket: Equatable {
    case overdue
    case today
    case thisWeek
    case later

    var header: String {
        switch self {
        case .overdue: return "overdue"
        case .today: return "today"
        case .thisWeek: return "this week"
        case .later: return "later"
        }
    }

    // The "due by today" group: overdue and today. Used for the recent list's top section and weight.
    var isTodayOrEarlier: Bool {
        self == .overdue || self == .today
    }

    static func classify(_ due: Date, now: Date, calendar: Calendar = .current) -> DueBucket {
        let delta = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: now),
            to: calendar.startOfDay(for: due)
        ).day ?? 0
        if delta < 0 { return .overdue }
        if delta == 0 { return .today }
        if delta <= 6 { return .thisWeek }
        return .later
    }
}
