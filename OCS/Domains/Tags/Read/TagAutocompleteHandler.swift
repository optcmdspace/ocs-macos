import Foundation

nonisolated final class TagAutocompleteHandler: Sendable {
    private let store: any TagAutocompleteStore

    init(store: any TagAutocompleteStore) {
        self.store = store
    }

    func handle(_ query: TagAutocompleteQuery) async throws -> [TagSuggestion] {
        do {
            return try await store.suggestions(prefix: query.prefix, limit: query.limit)
        } catch {
            throw QueryError.storage(underlying: error)
        }
    }
}
