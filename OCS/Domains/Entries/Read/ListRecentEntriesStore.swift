import Foundation

protocol ListRecentEntriesStore: Sendable {
    nonisolated func recentEntries(
        limit: Int,
        scope: ListRecentEntriesQuery.Scope,
        before: ListRecentEntriesQuery.Cursor?
    ) async throws -> [EntryListItem]
}
