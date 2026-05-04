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
            return [("↑↓", "to navigate"), ("⇥", "to complete"), ("⏎", "to run")]
        case .entries(let e):
            if e.list.isEmpty {
                return [("↑", "to go back")]
            }
            let enterLabel = e.list.selected?.bin == .done ? "to undo done" : "to mark done"
            return [("↑↓", "to navigate"), ("⏎", enterLabel), ("⌫", "to delete")]
        }
    }

    static func stat(from stats: EntryStats?) -> String {
        guard let s = stats, s.todayCount > 0 else { return "" }
        return "\(s.todayCount) today"
    }
}
