import Foundation

nonisolated final class ScheduleEntryHandler: Sendable {
    private let eventStore: any EventStore
    private let ids: any IDs

    init(eventStore: any EventStore, ids: any IDs) {
        self.eventStore = eventStore
        self.ids = ids
    }

    func handle(_ cmd: ScheduleEntryCommand) async throws {
        let event = EntryScheduled(
            id: ids.next(),
            entryId: cmd.entryId,
            dueAt: cmd.dueAt,
            deviceId: cmd.deviceId,
            createdAt: cmd.now
        )
        try await eventStore.append([event])
    }
}
