import Foundation
import GRDB

nonisolated final class EntryReadsGRDB: ListRecentEntriesStore {
    private let database: Database

    init(database: Database) {
        self.database = database
    }

    func recentEntries(
        limit: Int,
        before: ListRecentEntriesQuery.Cursor?
    ) async throws -> [EntryListItem] {
        try await database.queue.read { db in
            let rows: [Row]
            if let before {
                rows = try Row.fetchAll(
                    db,
                    sql: Queries.selectEntriesRecentBefore,
                    arguments: [
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
                    arguments: [limit]
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
            let createdAtMillis: Int64 = row["created_at"]
        else { return nil }
        return EntryListItem(
            id: id,
            text: text,
            createdAt: Date(timeIntervalSince1970: TimeInterval(createdAtMillis) / 1000)
        )
    }
}
