import Foundation

nonisolated struct EntriesListPageState: Sendable, Equatable {
    let list: TerminalListState<EntryListItem>
    let nextCursor: ListRecentEntriesQuery.Cursor?
    let isLoadingMore: Bool
    let exhausted: Bool
    let hasError: Bool

    static func empty(windowSize: Int) -> EntriesListPageState {
        EntriesListPageState(
            list: TerminalListState(windowSize: windowSize),
            nextCursor: nil,
            isLoadingMore: false,
            exhausted: false,
            hasError: false
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
            nextCursor: nextCursor,
            isLoadingMore: true,
            exhausted: exhausted,
            hasError: false
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
            nextCursor: newCursor,
            isLoadingMore: false,
            exhausted: more.isEmpty,
            hasError: false
        )
    }

    func failedLoad() -> EntriesListPageState {
        EntriesListPageState(
            list: list,
            nextCursor: nextCursor,
            isLoadingMore: false,
            exhausted: exhausted,
            hasError: true
        )
    }

    func cursorDown() -> EntriesListPageState { with(list: list.cursorDown()) }
    func cursorUp() -> EntriesListPageState { with(list: list.cursorUp()) }
    func pageDown() -> EntriesListPageState { with(list: list.pageDown()) }
    func pageUp() -> EntriesListPageState { with(list: list.pageUp()) }

    private func with(list newList: TerminalListState<EntryListItem>) -> EntriesListPageState {
        EntriesListPageState(
            list: newList,
            nextCursor: nextCursor,
            isLoadingMore: isLoadingMore,
            exhausted: exhausted,
            hasError: hasError
        )
    }
}
