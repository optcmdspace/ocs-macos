import Foundation

nonisolated final class GetEntryHandler: Sendable {
    private let store: any GetEntryStore

    init(store: any GetEntryStore) {
        self.store = store
    }

    func handle(_ query: GetEntryQuery) async throws -> EntryListItem {
        do {
            guard let item = try await store.entry(id: query.id) else {
                throw QueryError.notFound(query.id)
            }
            return item
        } catch let error as QueryError {
            throw error
        } catch {
            throw QueryError.storage(underlying: error)
        }
    }
}
