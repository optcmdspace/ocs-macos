import Foundation
import GRDB

// Must run inside the event-log insert's transaction, or projections drift from events.
nonisolated final class Projector: Sendable {
    func apply(_ event: any DomainEvent, in db: GRDB.Database) throws {
        switch event {
        case let e as EntryCaptured:
            try applyEntryCaptured(e, in: db)
        case let e as EntryMoved:
            try applyEntryMoved(e, in: db)
        default:
            preconditionFailure("Projector: unknown event \(type(of: event))")
        }
    }

    private func applyEntryCaptured(_ event: EntryCaptured, in db: GRDB.Database) throws {
        let createdAt = event.createdAt.unixMillis
        try db.execute(
            sql: Queries.projectEntryCaptured,
            arguments: [
                event.entryId.uuidString,
                event.text,
                createdAt,
                createdAt,
            ]
        )
    }

    private func applyEntryMoved(_ event: EntryMoved, in db: GRDB.Database) throws {
        try db.execute(
            sql: Queries.projectEntryMoved,
            arguments: [
                event.toBin.rawValue,
                event.createdAt.unixMillis,
                event.entryId.uuidString,
            ]
        )
    }
}
