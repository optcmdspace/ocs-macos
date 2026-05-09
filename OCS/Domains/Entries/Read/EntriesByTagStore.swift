import Foundation

protocol EntriesByTagStore: Sendable {
    nonisolated func entries(
        tagName: String,
        scope: ListRecentEntriesQuery.Scope,
        limit: Int,
        before: ListRecentEntriesQuery.Cursor?
    ) async throws -> [EntryListItem]
}
