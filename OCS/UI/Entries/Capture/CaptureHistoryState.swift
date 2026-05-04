import Foundation

nonisolated struct CaptureHistoryState: Sendable, Equatable {
    let items: [EntryListItem]
    let index: Int
    let draft: String
    let itemsLoaded: Bool

    static let empty = CaptureHistoryState(items: [], index: 0, draft: "", itemsLoaded: false)

    var isActive: Bool { index > 0 }

    var recalledText: String? {
        guard index > 0, index <= items.count else { return nil }
        return items[index - 1].text
    }

    var displayText: String { recalledText ?? draft }

    func steppingBack(currentField: String) -> CaptureHistoryState {
        guard !items.isEmpty else { return self }
        let nextIndex = min(index + 1, items.count)
        let nextDraft = (index == 0) ? currentField : draft
        return CaptureHistoryState(items: items, index: nextIndex, draft: nextDraft, itemsLoaded: itemsLoaded)
    }

    func steppingForward() -> CaptureHistoryState {
        guard index > 0 else { return self }
        return CaptureHistoryState(items: items, index: index - 1, draft: draft, itemsLoaded: itemsLoaded)
    }

    func exitingRecall(currentField: String) -> CaptureHistoryState {
        CaptureHistoryState(items: items, index: 0, draft: currentField, itemsLoaded: itemsLoaded)
    }

    func adopting(_ newItems: [EntryListItem]) -> CaptureHistoryState {
        let safeIndex = min(index, newItems.count)
        return CaptureHistoryState(items: newItems, index: safeIndex, draft: draft, itemsLoaded: true)
    }
}
