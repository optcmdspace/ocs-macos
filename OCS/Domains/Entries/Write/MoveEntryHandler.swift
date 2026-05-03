import Foundation

nonisolated final class MoveEntryHandler: Sendable {
    private let eventStore: any EventStore
    private let ids: any IDs

    init(eventStore: any EventStore, ids: any IDs) {
        self.eventStore = eventStore
        self.ids = ids
    }

    func handle(_ cmd: MoveEntryCommand) async throws {
        let event = EntryMoved(
            id: ids.next(),
            entryId: cmd.entryId,
            toBin: cmd.toBin,
            deviceId: cmd.deviceId,
            createdAt: cmd.now
        )
        try await eventStore.append([event])
    }
}
