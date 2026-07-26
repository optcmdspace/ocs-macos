import Foundation

nonisolated final class ListDueEntriesHandler: Sendable {
    private let store: any ListDueEntriesStore

    init(store: any ListDueEntriesStore) {
        self.store = store
    }

    func handle(_ query: ListDueEntriesQuery) async throws -> [EntryListItem] {
        try await store.dueEntries(limit: query.limit)
    }
}
