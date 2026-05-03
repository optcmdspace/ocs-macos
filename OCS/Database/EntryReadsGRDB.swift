import Foundation
import GRDB

nonisolated final class EntryReadsGRDB: ListRecentEntriesStore {
    private let database: Database

    init(database: Database) {
        self.database = database
    }

    func recentEntries(
        limit: Int,
        scope: ListRecentEntriesQuery.Scope,
        before: ListRecentEntriesQuery.Cursor?
    ) async throws -> [EntryListItem] {
        try await database.queue.read { db in
            let includeDone: Int = scope == .all ? 1 : 0
            let rows: [Row]
            if let before {
                rows = try Row.fetchAll(
                    db,
                    sql: Queries.selectEntriesRecentBefore,
                    arguments: [
                        includeDone,
                        before.createdAtMillis,
                        before.createdAtMillis,
                        before.id.uuidString,
                        limit,
                    ]
                )
            } else {
                rows = try Row.fetchAll(
                    db,
                    sql: Queries.selectEntriesRecent,
                    arguments: [includeDone, limit]
                )
            }
            return rows.compactMap(Self.mapRow)
        }
    }

    // Drops rows whose id text is not parseable as a UUID; the schema CHECK and our writers prevent this in practice.
    private static func mapRow(_ row: Row) -> EntryListItem? {
        guard
            let idText: String = row["id"],
            let id = UUID(uuidString: idText),
            let text: String = row["text"],
            let binText: String = row["bin"],
            let bin = Bin(rawValue: binText),
            let createdAtMillis: Int64 = row["created_at"]
        else { return nil }
        return EntryListItem(
            id: id,
            text: text,
            bin: bin,
            createdAt: Date(timeIntervalSince1970: TimeInterval(createdAtMillis) / 1000)
        )
    }
}
