import Foundation

protocol ListRecentEntriesStore: Sendable {
    nonisolated func recentEntries(
        limit: Int,
        before: ListRecentEntriesQuery.Cursor?
    ) async throws -> [EntryListItem]
}
