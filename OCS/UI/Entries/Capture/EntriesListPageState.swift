import Foundation

nonisolated struct EntriesListPageState: Sendable, Equatable {
    let list: TerminalListState<EntryRow>
    let scope: ListRecentEntriesQuery.Scope
    let filter: EntriesFilter
    let nextCursor: ListRecentEntriesQuery.Cursor?
    let isLoadingMore: Bool
    let exhausted: Bool
    let hasError: Bool
    // Stays false during the first ~100ms of a load so a fast query doesn't flicker the spinner.
    let loadingVisible: Bool

    static func empty(windowSize: Int, scope: ListRecentEntriesQuery.Scope, filter: EntriesFilter = .none) -> EntriesListPageState {
        EntriesListPageState(
            list: TerminalListState(windowSize: windowSize),
            scope: scope,
            filter: filter,
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
            filter: filter,
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
            filter: filter,
            nextCursor: nextCursor,
            isLoadingMore: isLoadingMore,
            exhausted: exhausted,
            hasError: hasError,
            loadingVisible: true
        )
    }

    func appending(_ more: [EntryListItem], requestedLimit: Int) -> EntriesListPageState {
        let nextList = list.appending(more.map(EntryRow.entry))
        // The keyset cursor tracks the last real entry; disclosure rows never paginate.
        let lastSeen = more.last ?? list.items.compactMap(\.entry).last
        let newCursor: ListRecentEntriesQuery.Cursor? = lastSeen.map {
            .init(
                doneRank: $0.bin == .done ? 1 : 0,
                effectiveDueMillis: $0.dueAt?.unixMillis ?? Int64.max,
                createdAtMillis: $0.createdAt.unixMillis,
                id: $0.id
            )
        }
        return EntriesListPageState(
            list: nextList,
            scope: scope,
            filter: filter,
            nextCursor: newCursor,
            isLoadingMore: false,
            exhausted: more.count < requestedLimit,
            hasError: false,
            loadingVisible: false
        )
    }

    func failedLoad() -> EntriesListPageState {
        EntriesListPageState(
            list: list,
            scope: scope,
            filter: filter,
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
        with(list: list.replacingSelected(with: .entry(item)))
    }

    func replacing(at index: Int, with item: EntryListItem) -> EntriesListPageState {
        with(list: list.replacing(at: index, with: .entry(item)))
    }

    func removingSelected() -> EntriesListPageState {
        with(list: list.removingSelected())
    }

    // Prepends the collapsed past-due summary as a selectable row, nudging the cursor so it stays on
    // the same entry. Idempotent, so paginated appends don't add a second one.
    func withLeadingCollapsedOverdue(count: Int) -> EntriesListPageState {
        guard count > 0 else { return self }
        if case .collapsedOverdue = list.items.first { return self }
        let items = [EntryRow.collapsedOverdue(count: count)] + list.items
        return with(list: TerminalListState(items: items, cursor: list.cursor + 1, windowSize: list.windowSize))
    }

    private func with(list newList: TerminalListState<EntryRow>) -> EntriesListPageState {
        EntriesListPageState(
            list: newList,
            scope: scope,
            filter: filter,
            nextCursor: nextCursor,
            isLoadingMore: isLoadingMore,
            exhausted: exhausted,
            hasError: hasError,
            loadingVisible: loadingVisible
        )
    }
}
