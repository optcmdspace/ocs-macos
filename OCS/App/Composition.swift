import Foundation

// Dispatch surface is plain closures so UI does not depend on Collaborators or Handlers.
nonisolated final class Composition: Sendable {
    let dispatchCapture: @Sendable (_ rawText: String) async throws -> EntryListItem
    let dispatchListRecent: @Sendable (_ limit: Int, _ scope: ListRecentEntriesQuery.Scope, _ before: ListRecentEntriesQuery.Cursor?) async throws -> [EntryListItem]
    let dispatchMove: @Sendable (_ entryId: UUID, _ toBin: Bin) async throws -> Void
    let dispatchEntryStats: @Sendable (_ todayStartMillis: Int64, _ yesterdayStartMillis: Int64, _ staleCutoffMillis: Int64) async throws -> EntryStats

    #if DEBUG
    let dispatchSeedCapture: @Sendable (_ text: String, _ at: Date) async -> Void
    #endif

    private let database: Database
    private let clock: any Clock
    private let ids: any IDs
    private let deviceId: UUID
    private let projector: Projector
    private let eventStore: any EventStore
    private let captureHandler: CaptureEntryHandler
    private let moveHandler: MoveEntryHandler
    private let entryReads: EntryReadsGRDB
    private let listRecentHandler: ListRecentEntriesHandler
    private let getEntryHandler: GetEntryHandler
    private let getEntryStatsHandler: GetEntryStatsHandler

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
        let moveHandler = MoveEntryHandler(eventStore: eventStore, ids: ids)
        let entryReads = EntryReadsGRDB(database: database)
        let listRecentHandler = ListRecentEntriesHandler(store: entryReads)
        let getEntryHandler = GetEntryHandler(store: entryReads)
        let getEntryStatsHandler = GetEntryStatsHandler(store: entryReads)

        self.database = database
        self.clock = clock
        self.ids = ids
        self.deviceId = deviceId
        self.projector = projector
        self.eventStore = eventStore
        self.captureHandler = captureHandler
        self.moveHandler = moveHandler
        self.entryReads = entryReads
        self.listRecentHandler = listRecentHandler
        self.getEntryHandler = getEntryHandler
        self.getEntryStatsHandler = getEntryStatsHandler
        self.dispatchCapture = { [captureHandler, getEntryHandler, clock, deviceId] rawText in
            let cmd = CaptureEntryCommand(
                rawText: rawText,
                deviceId: deviceId,
                now: clock.now()
            )
            let entryId = try await captureHandler.handle(cmd)
            return try await getEntryHandler.handle(GetEntryQuery(id: entryId))
        }
        self.dispatchListRecent = { [listRecentHandler] limit, scope, before in
            try await listRecentHandler.handle(ListRecentEntriesQuery(limit: limit, scope: scope, before: before))
        }
        self.dispatchMove = { [moveHandler, clock, deviceId] entryId, toBin in
            let cmd = MoveEntryCommand(
                entryId: entryId,
                toBin: toBin,
                deviceId: deviceId,
                now: clock.now()
            )
            try await moveHandler.handle(cmd)
        }
        self.dispatchEntryStats = { [getEntryStatsHandler] todayStartMillis, yesterdayStartMillis, staleCutoffMillis in
            try await getEntryStatsHandler.handle(
                GetEntryStatsQuery(
                    todayStartMillis: todayStartMillis,
                    yesterdayStartMillis: yesterdayStartMillis,
                    staleCutoffMillis: staleCutoffMillis
                )
            )
        }
        #if DEBUG
        self.dispatchSeedCapture = { [captureHandler, deviceId] text, at in
            let cmd = CaptureEntryCommand(rawText: text, deviceId: deviceId, now: at)
            _ = try? await captureHandler.handle(cmd)
        }
        #endif
    }
}
