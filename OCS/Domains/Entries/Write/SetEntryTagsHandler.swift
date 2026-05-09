import Foundation

nonisolated final class SetEntryTagsHandler: Sendable {
    private let eventStore: any EventStore
    private let ids: any IDs
    private let tagIdLookup: any TagIDLookup

    init(eventStore: any EventStore, ids: any IDs, tagIdLookup: any TagIDLookup) {
        self.eventStore = eventStore
        self.ids = ids
        self.tagIdLookup = tagIdLookup
    }

    func handle(_ cmd: SetEntryTagsCommand) async throws {
        let lookupNames = Array(Set(cmd.toAdd + cmd.toRemove))
        let known = try await tagIdLookup.activeIds(forNames: lookupNames)

        var events: [any DomainEvent] = []
        var resolvedAdd: [TagName: UUID] = [:]
        for name in cmd.toAdd {
            if let existing = known[name] {
                resolvedAdd[name] = existing
            } else {
                let tagId = ids.next()
                resolvedAdd[name] = tagId
                events.append(TagCreated(
                    id: ids.next(),
                    tagId: tagId,
                    name: name.value,
                    deviceId: cmd.deviceId,
                    createdAt: cmd.now
                ))
            }
        }
        for name in cmd.toAdd {
            guard let tagId = resolvedAdd[name] else { continue }
            events.append(EntryTagged(
                id: ids.next(),
                entryId: cmd.entryId,
                tagId: tagId,
                deviceId: cmd.deviceId,
                createdAt: cmd.now
            ))
        }
        for name in cmd.toRemove {
            guard let tagId = known[name] else { continue }
            events.append(EntryUntagged(
                id: ids.next(),
                entryId: cmd.entryId,
                tagId: tagId,
                deviceId: cmd.deviceId,
                createdAt: cmd.now
            ))
        }
        guard !events.isEmpty else { return }
        try await eventStore.append(events)
    }
}
