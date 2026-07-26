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
        if state.newTagDraft != nil {
            return [("⏎", "to add"), ("⌫", "to edit"), ("esc", "to cancel")]
        }
        let commitOrBack: Hint = state.hasChanges ? ("⏎", "to commit") : ("esc", "to back")
        return [("←→", "to move"), ("space", "to toggle"), ("any char", "for new"), commitOrBack]
    }

    static func stat(from stats: EntryStats?) -> String {
        guard let s = stats, s.todayCount > 0 else { return "" }
        return "\(s.todayCount) today"
    }
}
