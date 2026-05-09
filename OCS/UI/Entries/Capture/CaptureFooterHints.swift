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
            if e.list.isEmpty {
                return [("↑", "to go back")]
            }
            let enterLabel = e.list.selected?.bin == .done ? "to undo done" : "to mark done"
            return [("↑↓", "to navigate"), ("⏎", enterLabel), ("⌫", "to delete"), ("t", "to tag")]
        case .findResults(let e):
            if e.list.isEmpty {
                return [("type", "to refine"), ("⌫", "to edit")]
            }
            let enterLabel = e.list.selected?.bin == .done ? "to undo done" : "to mark done"
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
