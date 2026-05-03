import Foundation

nonisolated struct ListRecentEntriesQuery: Sendable {
    let limit: Int
    let scope: Scope
    let before: Cursor?

    init(limit: Int, scope: Scope, before: Cursor? = nil) {
        self.limit = limit
        self.scope = scope
        self.before = before
    }

    nonisolated enum Scope: Sendable, Equatable {
        case active
        case all
    }

    nonisolated struct Cursor: Sendable, Equatable {
        let createdAtMillis: Int64
        let id: UUID
    }
}
