import Foundation
import os

nonisolated final class CaptureEntryHandler: Sendable {
    private let eventStore: any EventStore
    private let ids: any IDs
    private let tagIdLookup: any TagIDLookup

    init(eventStore: any EventStore, ids: any IDs, tagIdLookup: any TagIDLookup) {
        self.eventStore = eventStore
        self.ids = ids
        self.tagIdLookup = tagIdLookup
    }

    func handle(_ cmd: CaptureEntryCommand) async throws -> UUID {
        let interval = Signposts.signposter.beginInterval("handler-capture")
        defer { Signposts.signposter.endInterval("handler-capture", interval) }
        let parsed = HashtagParser.parse(cmd.rawText)
        let dated = DueDateParser.parse(parsed.body, now: cmd.now)
        guard let text = EntryText(dated.body) else {
            throw CommandError.validationFailed("entry text empty after trimming")
        }
        let known = try await tagIdLookup.activeIds(forNames: parsed.tags)
        let entryId = ids.next()
        var events: [any DomainEvent] = []
        var resolved: [TagName: UUID] = [:]
        for name in parsed.tags {
            if let existing = known[name] {
                resolved[name] = existing
            } else {
                let tagId = ids.next()
                resolved[name] = tagId
                events.append(TagCreated(
                    id: ids.next(),
                    tagId: tagId,
                    name: name.value,
                    deviceId: cmd.deviceId,
                    createdAt: cmd.now
                ))
            }
        }
        events.append(EntryCaptured(
            id: ids.next(),
            entryId: entryId,
            text: text.value,
            deviceId: cmd.deviceId,
            createdAt: cmd.now
        ))
        if let dueAt = dated.dueAt {
            events.append(EntryScheduled(
                id: ids.next(),
                entryId: entryId,
                dueAt: dueAt,
                deviceId: cmd.deviceId,
                createdAt: cmd.now
            ))
        }
        for name in parsed.tags {
            guard let tagId = resolved[name] else { continue }
            events.append(EntryTagged(
                id: ids.next(),
                entryId: entryId,
                tagId: tagId,
                deviceId: cmd.deviceId,
                createdAt: cmd.now
            ))
        }
        try await eventStore.append(events)
        return entryId
    }
}
