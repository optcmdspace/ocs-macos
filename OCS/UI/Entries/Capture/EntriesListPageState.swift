import Foundation

nonisolated struct EntriesListPageState: Sendable, Equatable {
    let list: TerminalListState<EntryListItem>
    let scope: ListRecentEntriesQuery.Scope
    let nextCursor: ListRecentEntriesQuery.Cursor?
    let isLoadingMore: Bool
    let exhausted: Bool
    let hasError: Bool
    // Stays false during the first ~100ms of a load so a fast query doesn't flicker the spinner.
    let loadingVisible: Bool

    static func empty(windowSize: Int, scope: ListRecentEntriesQuery.Scope) -> EntriesListPageState {
        EntriesListPageState(
            list: TerminalListState(windowSize: windowSize),
            scope: scope,
            nextCursor: nil,
            isLoadingMore: false,
            exhausted: false,
            hasError: false,
            loadingVisible: false
        )
    }

    private static let loadAheadThreshold = 5

    var shouldLoadMore: Bool {
        guard !isLoadingMore, !exhausted, !hasError, !list.isEmpty else { return false }
        return list.count - list.cursor <= Self.loadAheadThreshold
    }

    func startingLoad() -> EntriesListPageState {
        EntriesListPageState(
            list: list,
            scope: scope,
            nextCursor: nextCursor,
            isLoadingMore: true,
            exhausted: exhausted,
            hasError: false,
            loadingVisible: loadingVisible
        )
    }

    func revealingLoad() -> EntriesListPageState {
        EntriesListPageState(
            list: list,
            scope: scope,
            nextCursor: nextCursor,
            isLoadingMore: isLoadingMore,
            exhausted: exhausted,
            hasError: hasError,
            loadingVisible: true
        )
    }

    func appending(_ more: [EntryListItem]) -> EntriesListPageState {
        let nextList = list.appending(more)
        let lastSeen = more.last ?? list.items.last
        let newCursor: ListRecentEntriesQuery.Cursor? = lastSeen.map {
            .init(
                createdAtMillis: Int64(($0.createdAt.timeIntervalSince1970 * 1000).rounded()),
                id: $0.id
            )
        }
        return EntriesListPageState(
            list: nextList,
            scope: scope,
            nextCursor: newCursor,
            isLoadingMore: false,
            exhausted: more.isEmpty,
            hasError: false,
            loadingVisible: false
        )
    }

    func failedLoad() -> EntriesListPageState {
        EntriesListPageState(
            list: list,
            scope: scope,
            nextCursor: nextCursor,
            isLoadingMore: false,
            exhausted: exhausted,
            hasError: true,
            loadingVisible: false
        )
    }

    func cursorDown() -> EntriesListPageState { with(list: list.cursorDown()) }
    func cursorUp() -> EntriesListPageState { with(list: list.cursorUp()) }
    func pageDown() -> EntriesListPageState { with(list: list.pageDown()) }
    func pageUp() -> EntriesListPageState { with(list: list.pageUp()) }

    func replacingSelected(with item: EntryListItem) -> EntriesListPageState {
        with(list: list.replacingSelected(with: item))
    }

    func removingSelected() -> EntriesListPageState {
        with(list: list.removingSelected())
    }

    private func with(list newList: TerminalListState<EntryListItem>) -> EntriesListPageState {
        EntriesListPageState(
            list: newList,
            scope: scope,
            nextCursor: nextCursor,
            isLoadingMore: isLoadingMore,
            exhausted: exhausted,
            hasError: hasError,
            loadingVisible: loadingVisible
        )
    }
}
