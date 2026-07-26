import Foundation

protocol ListRecentEntriesStore: Sendable {
    nonisolated func recentEntries(
        limit: Int,
        scope: ListRecentEntriesQuery.Scope,
        before: ListRecentEntriesQuery.Cursor?,
        includeOverdue: Bool,
        overdueBeforeMillis: Int64
    ) async throws -> [EntryListItem]
}
