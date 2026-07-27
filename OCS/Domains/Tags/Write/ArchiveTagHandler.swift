import Foundation

nonisolated final class ArchiveTagHandler: Sendable {
    private let eventStore: any EventStore
    private let ids: any IDs

    init(eventStore: any EventStore, ids: any IDs) {
        self.eventStore = eventStore
        self.ids = ids
    }

    func handle(_ cmd: ArchiveTagCommand) async throws {
        try await eventStore.append([
            TagArchived(
                id: ids.next(),
                tagId: cmd.tagId,
                deviceId: cmd.deviceId,
                createdAt: cmd.now
            ),
        ])
    }
}
