import Foundation
import os

nonisolated final class CaptureEntryHandler: Sendable {
    private let eventStore: any EventStore
    private let ids: any IDs

    init(eventStore: any EventStore, ids: any IDs) {
        self.eventStore = eventStore
        self.ids = ids
    }

    func handle(_ cmd: CaptureEntryCommand) async throws -> UUID {
        let interval = Signposts.signposter.beginInterval("handler-capture")
        defer { Signposts.signposter.endInterval("handler-capture", interval) }
        guard let text = EntryText(cmd.rawText) else {
            throw CommandError.validationFailed("entry text empty after trimming")
        }
        let entryId = ids.next()
        let event = EntryCaptured(
            id: ids.next(),
            entryId: entryId,
            text: text.value,
            deviceId: cmd.deviceId,
            createdAt: cmd.now
        )
        try await eventStore.append([event])
        return entryId
    }
}
