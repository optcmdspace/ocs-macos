import Foundation

@MainActor
enum CaptureFooterHints {
    typealias Hint = (key: String, label: String)

    static func hints(for page: CapturePageMode, fieldText: String) -> [Hint] {
        switch page {
        case .idle:
            if fieldText.isEmpty {
                return [("↓", "for list")]
            }
            return [("⏎", "to submit"), ("⌘⏎", "to submit and continue")]
        case .suggestions:
            return [("↑↓", "to navigate"), ("tab", "to complete"), ("⏎", "to run")]
        case .tagSuggestions:
            return [("↑↓", "to navigate"), ("tab", "to complete"), ("⏎", "to submit")]
        case .entries(let e):
            guard let selected = e.list.selected else {
                return [("↑", "to go back")]
            }
            switch selected {
            case .collapsedOverdue(let count):
                return [("↑↓", "to navigate"), ("→", "show \(count) earlier")]
            case .entry(let item):
                let enterLabel = item.bin == .done ? "to undo done" : "to mark done"
                var hints: [Hint] = [("↑↓", "to navigate"), ("⏎", enterLabel), ("d", "to schedule"), ("t", "to tag")]
                if case .none = e.filter, let due = item.dueAt, DueBucket.classify(due, now: Date()) == .overdue {
                    hints.append(("←", "hide earlier"))
                }
                return hints
            }
        case .findResults(let e):
            if e.list.isEmpty {
                if case .due = e.filter { return [("esc", "to dismiss")] }
                return [("type", "to refine"), ("⌫", "to edit")]
            }
            let enterLabel = e.list.selected?.entry?.bin == .done ? "to undo done" : "to mark done"
            return [("↑↓", "to navigate"), ("⏎", enterLabel)]
        }
    }

    static func hints(forTagEdit state: TagEditState) -> [Hint] {
        var hints: [Hint] = [
            ("←→", "to move"),
            ("space", state.isNewSlotFocused ? "to create" : "to toggle"),
            state.query.isEmpty ? ("type", "to filter") : ("⌫", "to edit"),
        ]
        if state.hasChanges {
            hints.append(("⏎", "to commit"))
        } else if !state.query.isEmpty {
            hints.append(("esc", "to clear"))
        } else {
            hints.append(("esc", "to back"))
        }
        return hints
    }

    static func stat(from stats: EntryStats?) -> String {
        guard let s = stats, s.todayCount > 0 else { return "" }
        return "\(s.todayCount) today"
    }
}
