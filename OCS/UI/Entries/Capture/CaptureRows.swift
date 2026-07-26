import AppKit

@MainActor
enum CaptureRows {
    static func suggestion(_ spec: SlashCommand.Spec) -> TerminalRow.Spec {
        .init(primary: spec.display, secondary: spec.description, style: .command)
    }

    static func tagSuggestion(_ s: TagSuggestion, trailingMinWidth: CGFloat) -> TerminalRow.Spec {
        .init(
            primary: "#\(s.name)",
            trailing: s.usageCount > 0 ? "\(s.usageCount)" : nil,
            trailingMinWidth: trailingMinWidth
        )
    }

    static func entry(_ item: EntryListItem, now: Date, trailingMinWidth: CGFloat, style: TerminalRow.Style, highlight: String? = nil) -> TerminalRow.Spec {
        .init(
            primary: item.text,
            tags: item.tags.isEmpty ? nil : item.tags,
            trailing: item.dueAt.map { dueStamp(from: $0, now: now) },
            trailingMinWidth: trailingMinWidth,
            style: style,
            strikethrough: item.bin == .done,
            highlight: highlight
        )
    }

    static func preview(_ item: EntryListItem, now: Date, trailingMinWidth: CGFloat, highlighted: Bool = false) -> TerminalRow.Spec {
        .init(
            primary: item.text,
            tags: item.tags.isEmpty ? nil : item.tags,
            trailing: item.dueAt.map { dueStamp(from: $0, now: now) },
            trailingMinWidth: trailingMinWidth,
            style: highlighted ? .normal : .muted,
            strikethrough: item.bin == .done
        )
    }

    // Recent-list weight by due horizon: crisp for what's due today or overdue, a subtle fade for
    // everything still ahead or undated, faded for done.
    nonisolated static func recentStyle(for item: EntryListItem, now: Date) -> TerminalRow.Style {
        if item.bin == .done { return .faint }
        return dueTodayOrEarlier(item, now: now) ? .normal : .soft
    }

    // A non-done entry whose due date is today or in the past.
    nonisolated static func dueTodayOrEarlier(_ item: EntryListItem, now: Date) -> Bool {
        guard item.bin != .done, let due = item.dueAt else { return false }
        return DueBucket.classify(due, now: now).isTodayOrEarlier
    }

    // Search and agenda don't fade by capture age; only done recedes.
    nonisolated static func plainStyle(for item: EntryListItem) -> TerminalRow.Style {
        item.bin == .done ? .faint : .normal
    }

    // Future-facing day stamp. Uses calendar-day boundaries so "today"/"tomorrow" and weekday names
    // read cleanly regardless of the exact capture time.
    nonisolated static func dueStamp(from due: Date, now: Date) -> String {
        let cal = Calendar.current
        let startNow = cal.startOfDay(for: now)
        let startDue = cal.startOfDay(for: due)
        let delta = cal.dateComponents([.day], from: startNow, to: startDue).day ?? 0
        if delta < 0 { return "overdue" }
        if delta == 0 { return "today" }
        if delta == 1 { return "tomorrow" }
        if delta <= 6 {
            let names = ["sun", "mon", "tue", "wed", "thu", "fri", "sat"]
            return names[(cal.component(.weekday, from: startDue) - 1) % 7]
        }
        let months = ["jan", "feb", "mar", "apr", "may", "jun", "jul", "aug", "sep", "oct", "nov", "dec"]
        let month = months[(cal.component(.month, from: startDue) - 1) % 12]
        return "\(month) \(cal.component(.day, from: startDue))"
    }
}
