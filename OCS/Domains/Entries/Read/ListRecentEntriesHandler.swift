import Foundation

nonisolated final class ListRecentEntriesHandler: Sendable {
    private let store: any ListRecentEntriesStore

    init(store: any ListRecentEntriesStore) {
        self.store = store
    }

    func handle(_ query: ListRecentEntriesQuery) async throws -> [EntryListItem] {
        do {
            return try await store.recentEntries(limit: query.limit, scope: query.scope, before: query.before)
        } catch {
            throw QueryError.storage(underlying: error)
        }
    }
}
