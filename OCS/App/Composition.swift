import Foundation

// Dispatch surface is `(String) -> UUID` so UI does not depend on Collaborators.
nonisolated final class Composition: Sendable {
    let dispatchCapture: @Sendable (_ rawText: String) async throws -> UUID

    private let database: Database
    private let clock: any Clock
    private let ids: any IDs
    private let deviceId: UUID
    private let projector: Projector
    private let eventStore: any EventStore
    private let captureHandler: CaptureEntryHandler

    init() throws {
        let database = try Database()
        let clock = SystemClock()
        let ids = UUIDv7IDs(clock: clock)

        let deviceId = try DeviceBootstrap.ensureLocalDevice(
            database: database,
            ids: ids,
            clock: clock
        )

        let projector = Projector()
        let eventStore = EventStoreGRDB(database: database, projector: projector)
        let captureHandler = CaptureEntryHandler(eventStore: eventStore, ids: ids)

        self.database = database
        self.clock = clock
        self.ids = ids
        self.deviceId = deviceId
        self.projector = projector
        self.eventStore = eventStore
        self.captureHandler = captureHandler
        self.dispatchCapture = { [captureHandler, clock, deviceId] rawText in
            let cmd = CaptureEntryCommand(
                rawText: rawText,
                deviceId: deviceId,
                now: clock.now()
            )
            return try await captureHandler.handle(cmd)
        }
    }
}
