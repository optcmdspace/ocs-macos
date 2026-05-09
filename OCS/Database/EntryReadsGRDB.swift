import Foundation
import GRDB

nonisolated final class EntryReadsGRDB: ListRecentEntriesStore, GetEntryStore, GetEntryStatsStore, EntriesByTagStore {
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

    func entries(
        tagName: String,
        scope: ListRecentEntriesQuery.Scope,
        limit: Int,
        before: ListRecentEntriesQuery.Cursor?
    ) async throws -> [EntryListItem] {
        try await database.queue.read { db in
            let includeDone: Int = scope == .all ? 1 : 0
            let rows: [Row]
            if let before {
                rows = try Row.fetchAll(
                    db,
                    sql: Queries.selectEntriesByTagBefore,
                    arguments: [
                        tagName,
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
                    sql: Queries.selectEntriesByTag,
                    arguments: [tagName, includeDone, limit]
                )
            }
            return rows.compactMap(Self.mapRow)
        }
    }

    func entry(id: UUID) async throws -> EntryListItem? {
        try await database.queue.read { db in
            let row = try Row.fetchOne(
                db,
                sql: Queries.selectEntryById,
                arguments: ["id": id.uuidString]
            )
            return row.flatMap(Self.mapRow)
        }
    }

    func entryStats(
        todayStartMillis: Int64,
        yesterdayStartMillis: Int64,
        staleCutoffMillis: Int64
    ) async throws -> EntryStats {
        try await database.queue.read { db in
            let row = try Row.fetchOne(
                db,
                sql: Queries.selectEntryStats,
                arguments: [
                    "todayStart": todayStartMillis,
                    "yesterdayStart": yesterdayStartMillis,
                    "staleCutoff": staleCutoffMillis,
                ]
            )
            guard let row else {
                return EntryStats(todayCount: 0, yesterdayCount: 0, activeCount: 0, staleActiveCount: 0)
            }
            let today: Int64 = row["today_count"] ?? 0
            let yesterday: Int64 = row["yesterday_count"] ?? 0
            let active: Int64 = row["active_count"] ?? 0
            let staleActive: Int64 = row["stale_active_count"] ?? 0
            return EntryStats(
                todayCount: Int(today),
                yesterdayCount: Int(yesterday),
                activeCount: Int(active),
                staleActiveCount: Int(staleActive)
            )
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
        let tagsCsv: String? = row["tags"]
        let tags: [String] = tagsCsv.map { $0.split(separator: ",").map(String.init) } ?? []
        return EntryListItem(
            id: id,
            text: text,
            bin: bin,
            createdAt: Date(timeIntervalSince1970: TimeInterval(createdAtMillis) / 1000),
            tags: tags
        )
    }
}
