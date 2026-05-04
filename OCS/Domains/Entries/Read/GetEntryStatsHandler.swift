import Foundation

nonisolated final class GetEntryStatsHandler: Sendable {
    private let store: any GetEntryStatsStore

    init(store: any GetEntryStatsStore) {
        self.store = store
    }

    func handle(_ query: GetEntryStatsQuery) async throws -> EntryStats {
        do {
            return try await store.entryStats(
                todayStartMillis: query.todayStartMillis,
                yesterdayStartMillis: query.yesterdayStartMillis,
                staleCutoffMillis: query.staleCutoffMillis
            )
        } catch {
            throw QueryError.storage(underlying: error)
        }
    }
}
