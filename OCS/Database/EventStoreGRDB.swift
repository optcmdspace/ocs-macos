import Foundation
import GRDB

// Append and projector apply must commit together; partial visibility would corrupt the read side.
nonisolated final class EventStoreGRDB: EventStore {
    private let database: Database
    private let projector: Projector

    init(database: Database, projector: Projector) {
        self.database = database
        self.projector = projector
    }

    func append(_ events: [any DomainEvent]) async throws {
        let projector = self.projector
        do {
            try await database.queue.write { db in
                for event in events {
                    try Self.insert(event, in: db)
                }
                for event in events {
                    try projector.apply(event, in: db)
                }
            }
        } catch {
            throw CommandError.storage(underlying: error)
        }
    }

    private static func insert(_ event: any DomainEvent, in db: GRDB.Database) throws {
        switch event {
        case let e as EntryCaptured:
            try insertEntryCaptured(e, in: db)
        case let e as EntryMoved:
            try insertEntryMoved(e, in: db)
        default:
            preconditionFailure("EventStoreGRDB: unknown event \(type(of: event))")
        }
    }

    private static func insertEntryCaptured(_ event: EntryCaptured, in db: GRDB.Database) throws {
        try db.execute(
            sql: Queries.insertEntryEventCaptured,
            arguments: [
                event.id.uuidString,
                event.entryId.uuidString,
                event.text,
                event.deviceId.uuidString,
                event.createdAt.unixMillis,
            ]
        )
    }

    private static func insertEntryMoved(_ event: EntryMoved, in db: GRDB.Database) throws {
        try db.execute(
            sql: Queries.insertEntryEventMoved,
            arguments: [
                event.id.uuidString,
                event.entryId.uuidString,
                event.toBin.rawValue,
                event.deviceId.uuidString,
                event.createdAt.unixMillis,
            ]
        )
    }
}
