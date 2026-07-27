import Foundation

nonisolated final class ListTagsHandler: Sendable {
    private let store: any ListTagsStore

    init(store: any ListTagsStore) {
        self.store = store
    }

    func handle(_ query: ListTagsQuery) async throws -> [TagListItem] {
        do {
            return try await store.listTags(prefix: query.prefix, limit: query.limit)
        } catch {
            throw QueryError.storage(underlying: error)
        }
    }
}
