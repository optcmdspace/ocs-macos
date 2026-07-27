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
        case let e as EntryTagged:
            try applyEntryTagged(e, in: db)
        case let e as EntryUntagged:
            try applyEntryUntagged(e, in: db)
        case let e as EntryScheduled:
            try applyEntryScheduled(e, in: db)
        case let e as TagCreated:
            try applyTagCreated(e, in: db)
        case let e as TagArchived:
            try applyTagArchived(e, in: db)
        case let e as TagUnarchived:
            try applyTagUnarchived(e, in: db)
        default:
            preconditionFailure("Projector: unknown event \(type(of: event))")
        }
    }

    private func applyEntryScheduled(_ event: EntryScheduled, in db: GRDB.Database) throws {
        try db.execute(
            sql: Queries.projectEntryScheduled,
            arguments: [
                event.dueAt?.unixMillis,
                event.createdAt.unixMillis,
                event.entryId.uuidString,
            ]
        )
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

    private func applyEntryTagged(_ event: EntryTagged, in db: GRDB.Database) throws {
        let canonical = try String.fetchOne(
            db,
            sql: Queries.selectTagCanonical,
            arguments: [event.tagId.uuidString]
        )
        guard let resolvedTagId = canonical else { return }
        try db.execute(
            sql: Queries.projectEntryTagged,
            arguments: [event.entryId.uuidString, resolvedTagId]
        )
        try db.execute(
            sql: Queries.projectEntryTaggedTouch,
            arguments: [event.createdAt.unixMillis, event.entryId.uuidString]
        )
    }

    private func applyEntryUntagged(_ event: EntryUntagged, in db: GRDB.Database) throws {
        let canonical = try String.fetchOne(
            db,
            sql: Queries.selectTagCanonical,
            arguments: [event.tagId.uuidString]
        )
        guard let resolvedTagId = canonical else { return }
        try db.execute(
            sql: Queries.projectEntryUntagged,
            arguments: [event.entryId.uuidString, resolvedTagId]
        )
        try db.execute(
            sql: Queries.projectEntryTaggedTouch,
            arguments: [event.createdAt.unixMillis, event.entryId.uuidString]
        )
    }

    // Lower UUIDv7 wins on name collision (SCHEMA.md L378-418).
    private func applyTagCreated(_ event: TagCreated, in db: GRDB.Database) throws {
        let createdAt = event.createdAt.unixMillis
        let incomingId = event.tagId.uuidString
        let name = event.name

        guard let existingId = try String.fetchOne(
            db,
            sql: Queries.selectTagActiveByName,
            arguments: [name]
        ) else {
            try db.execute(
                sql: Queries.projectTagCreated,
                arguments: [incomingId, name, incomingId, createdAt]
            )
            return
        }
        if existingId == incomingId { return }

        if existingId < incomingId {
            try db.execute(
                sql: Queries.projectTagCreated,
                arguments: [incomingId, name, existingId, createdAt]
            )
            return
        }

        try db.execute(
            sql: Queries.projectTagCreated,
            arguments: [incomingId, name, incomingId, createdAt]
        )
        try db.execute(
            sql: Queries.projectTagDemote,
            arguments: [incomingId, existingId]
        )
        try db.execute(
            sql: Queries.projectTagMigrateEntryTags,
            arguments: [incomingId, existingId]
        )
        try db.execute(
            sql: Queries.projectTagClearEntryTags,
            arguments: [existingId]
        )
        try db.execute(
            sql: Queries.projectTagFlattenChains,
            arguments: [incomingId, existingId]
        )
    }

    private func applyTagArchived(_ event: TagArchived, in db: GRDB.Database) throws {
        let canonical = try String.fetchOne(
            db,
            sql: Queries.selectTagCanonical,
            arguments: [event.tagId.uuidString]
        )
        guard let resolvedTagId = canonical else { return }
        try db.execute(
            sql: Queries.projectTagArchived,
            arguments: [event.createdAt.unixMillis, resolvedTagId]
        )
    }

    private func applyTagUnarchived(_ event: TagUnarchived, in db: GRDB.Database) throws {
        let canonical = try String.fetchOne(
            db,
            sql: Queries.selectTagCanonical,
            arguments: [event.tagId.uuidString]
        )
        guard let resolvedTagId = canonical else { return }
        try db.execute(
            sql: Queries.projectTagUnarchived,
            arguments: [resolvedTagId]
        )
    }
}
