import Foundation

nonisolated final class EntriesByTagHandler: Sendable {
    private let store: any EntriesByTagStore

    init(store: any EntriesByTagStore) {
        self.store = store
    }

    func handle(_ query: EntriesByTagQuery) async throws -> [EntryListItem] {
        do {
            return try await store.entries(
                tagName: query.tagName.value,
                scope: query.scope,
                limit: query.limit,
                before: query.before
            )
        } catch {
            throw QueryError.storage(underlying: error)
        }
    }
}
