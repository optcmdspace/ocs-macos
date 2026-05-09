import Foundation
import GRDB

nonisolated final class TagReadsGRDB: TagAutocompleteStore {
    private let database: Database

    init(database: Database) {
        self.database = database
    }

    func suggestions(prefix: String, limit: Int) async throws -> [TagSuggestion] {
        try await database.queue.read { db in
            let rows = try Row.fetchAll(
                db,
                sql: Queries.selectTagSuggestions,
                arguments: [prefix.lowercased(), limit]
            )
            return rows.compactMap { row in
                guard let name: String = row["name"] else { return nil }
                let uses: Int64 = row["uses"] ?? 0
                return TagSuggestion(name: name, usageCount: Int(uses))
            }
        }
    }
}
