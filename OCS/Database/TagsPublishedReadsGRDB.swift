import Foundation
import GRDB

nonisolated final class TagsPublishedReadsGRDB: TagIDLookup {
    private let database: Database

    init(database: Database) {
        self.database = database
    }

    func activeIds(forNames names: [TagName]) async throws -> [TagName: UUID] {
        guard !names.isEmpty else { return [:] }
        let payload = try JSONEncoder().encode(names.map(\.value))
        let json = String(decoding: payload, as: UTF8.self)
        return try await database.queue.read { db in
            let rows = try Row.fetchAll(
                db,
                sql: Queries.selectTagsActiveByNames,
                arguments: [json]
            )
            var result: [TagName: UUID] = [:]
            for row in rows {
                guard
                    let nameValue: String = row["name"],
                    let idText: String = row["id"],
                    let id = UUID(uuidString: idText),
                    let tagName = TagName(nameValue)
                else { continue }
                result[tagName] = id
            }
            return result
        }
    }
}
