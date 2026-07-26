import Foundation

nonisolated struct ListRecentEntriesQuery: Sendable {
    let limit: Int
    let scope: Scope
    let before: Cursor?
    let includeOverdue: Bool
    let overdueBeforeMillis: Int64

    init(limit: Int, scope: Scope, before: Cursor? = nil, includeOverdue: Bool = true, overdueBeforeMillis: Int64 = 0) {
        self.limit = limit
        self.scope = scope
        self.before = before
        self.includeOverdue = includeOverdue
        self.overdueBeforeMillis = overdueBeforeMillis
    }

    nonisolated enum Scope: Sendable, Equatable {
        case active
        case all
    }

    nonisolated struct Cursor: Sendable, Equatable {
        let doneRank: Int
        let effectiveDueMillis: Int64
        let createdAtMillis: Int64
        let id: UUID
    }
}
