import Foundation

protocol FindEntriesStore: Sendable {
    nonisolated func find(
        text: String?,
        tagNames: [String],
        scope: ListRecentEntriesQuery.Scope,
        limit: Int,
        before: ListRecentEntriesQuery.Cursor?
    ) async throws -> [EntryListItem]
}
