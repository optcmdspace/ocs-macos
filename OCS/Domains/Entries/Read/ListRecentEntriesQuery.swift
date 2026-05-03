import Foundation

nonisolated struct ListRecentEntriesQuery: Sendable {
    let limit: Int
    let before: Cursor?

    init(limit: Int, before: Cursor? = nil) {
        self.limit = limit
        self.before = before
    }

    nonisolated struct Cursor: Sendable, Equatable {
        let createdAtMillis: Int64
        let id: UUID
    }
}
