import Foundation

nonisolated struct FindEntriesQuery: Sendable {
    let text: String?
    let tagNames: [TagName]
    let scope: ListRecentEntriesQuery.Scope
    let limit: Int
    let before: ListRecentEntriesQuery.Cursor?

    init(
        text: String?,
        tagNames: [TagName],
        scope: ListRecentEntriesQuery.Scope,
        limit: Int,
        before: ListRecentEntriesQuery.Cursor? = nil
    ) {
        self.text = text
        self.tagNames = tagNames
        self.scope = scope
        self.limit = limit
        self.before = before
    }
}
