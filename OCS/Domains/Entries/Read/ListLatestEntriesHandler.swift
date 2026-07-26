import Foundation

nonisolated final class ListLatestEntriesHandler: Sendable {
    private let store: any ListLatestEntriesStore

    init(store: any ListLatestEntriesStore) {
        self.store = store
    }

    func handle(_ query: ListLatestEntriesQuery) async throws -> [EntryListItem] {
        try await store.latestEntries(limit: query.limit)
    }
}
