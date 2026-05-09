import Foundation

nonisolated struct EntriesByTagQuery: Sendable {
    let tagName: TagName
    let scope: ListRecentEntriesQuery.Scope
    let limit: Int
    let before: ListRecentEntriesQuery.Cursor?

    init(
        tagName: TagName,
        scope: ListRecentEntriesQuery.Scope,
        limit: Int,
        before: ListRecentEntriesQuery.Cursor? = nil
    ) {
        self.tagName = tagName
        self.scope = scope
        self.limit = limit
        self.before = before
    }
}
