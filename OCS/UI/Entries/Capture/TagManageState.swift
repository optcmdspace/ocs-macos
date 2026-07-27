import Foundation

nonisolated struct TagManageState: Sendable, Equatable {
    let list: TerminalListState<TagListItem>
    let query: String
    let loading: Bool
    let hasError: Bool

    static func empty(windowSize: Int, query: String) -> TagManageState {
        TagManageState(
            list: TerminalListState(windowSize: windowSize),
            query: query,
            loading: false,
            hasError: false
        )
    }

    func cursorDown() -> TagManageState { with(list: list.cursorDown()) }
    func cursorUp() -> TagManageState { with(list: list.cursorUp()) }
    func pageDown() -> TagManageState { with(list: list.pageDown()) }
    func pageUp() -> TagManageState { with(list: list.pageUp()) }

    func withQuery(_ query: String) -> TagManageState {
        TagManageState(list: list, query: query, loading: loading, hasError: hasError)
    }

    func startingLoad() -> TagManageState {
        TagManageState(list: list, query: query, loading: true, hasError: false)
    }

    func loaded(_ items: [TagListItem]) -> TagManageState {
        TagManageState(list: list.replacing(items), query: query, loading: false, hasError: false)
    }

    func failedLoad() -> TagManageState {
        TagManageState(list: list, query: query, loading: false, hasError: true)
    }

    func removingSelected() -> TagManageState {
        with(list: list.removingSelected())
    }

    // Restore a row at its prior position with the cursor on it, so undo doesn't jump the list.
    func inserting(_ tag: TagListItem, at index: Int) -> TagManageState {
        var items = list.items
        let i = max(0, min(index, items.count))
        items.insert(tag, at: i)
        return TagManageState(
            list: TerminalListState(items: items, cursor: i, windowSize: list.windowSize),
            query: query,
            loading: loading,
            hasError: hasError
        )
    }

    private func with(list newList: TerminalListState<TagListItem>) -> TagManageState {
        TagManageState(list: newList, query: query, loading: loading, hasError: hasError)
    }
}
