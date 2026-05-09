import Foundation

nonisolated final class FindEntriesHandler: Sendable {
    private let store: any FindEntriesStore

    init(store: any FindEntriesStore) {
        self.store = store
    }

    func handle(_ query: FindEntriesQuery) async throws -> [EntryListItem] {
        do {
            return try await store.find(
                text: query.text,
                tagNames: query.tagNames.map(\.value),
                scope: query.scope,
                limit: query.limit,
                before: query.before
            )
        } catch {
            throw QueryError.storage(underlying: error)
        }
    }
}
