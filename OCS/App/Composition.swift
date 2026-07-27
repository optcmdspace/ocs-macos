import Foundation

// Dispatch surface is plain closures so UI does not depend on Collaborators or Handlers.
nonisolated final class Composition: Sendable {
    let dispatchCapture: @Sendable (_ rawText: String) async throws -> EntryListItem
    let dispatchEntries: @Sendable (_ limit: Int, _ scope: ListRecentEntriesQuery.Scope, _ filter: EntriesFilter, _ before: ListRecentEntriesQuery.Cursor?) async throws -> [EntryListItem]
    let dispatchLatest: @Sendable (_ limit: Int) async throws -> [EntryListItem]
    let dispatchMove: @Sendable (_ entryId: UUID, _ toBin: Bin) async throws -> Void
    let dispatchSchedule: @Sendable (_ entryId: UUID, _ dueAt: Date?) async throws -> Void
    let dispatchEntryStats: @Sendable (_ todayStartMillis: Int64, _ yesterdayStartMillis: Int64, _ staleCutoffMillis: Int64) async throws -> EntryStats
    let dispatchTagSuggestions: DispatchTagSuggestions
    let dispatchSetEntryTags: DispatchSetEntryTags
    let dispatchListTags: DispatchListTags
    let dispatchArchiveTag: DispatchArchiveTag
    let dispatchUnarchiveTag: DispatchUnarchiveTag

    #if DEBUG
    let dispatchSeedCapture: @Sendable (_ text: String, _ at: Date) async -> Void
    #endif

    private let database: Database
    private let clock: any Clock
    private let ids: any IDs
    private let deviceId: UUID
    private let projector: Projector
    private let eventStore: any EventStore
    private let tagsPublishedReads: TagsPublishedReadsGRDB
    private let tagReads: TagReadsGRDB
    private let tagAutocompleteHandler: TagAutocompleteHandler
    private let listTagsHandler: ListTagsHandler
    private let archiveTagHandler: ArchiveTagHandler
    private let unarchiveTagHandler: UnarchiveTagHandler
    private let captureHandler: CaptureEntryHandler
    private let moveHandler: MoveEntryHandler
    private let scheduleHandler: ScheduleEntryHandler
    private let setEntryTagsHandler: SetEntryTagsHandler
    private let entryReads: EntryReadsGRDB
    private let listRecentHandler: ListRecentEntriesHandler
    private let findEntriesHandler: FindEntriesHandler
    private let listDueEntriesHandler: ListDueEntriesHandler
    private let listLatestEntriesHandler: ListLatestEntriesHandler
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
        let tagsPublishedReads = TagsPublishedReadsGRDB(database: database)
        let tagReads = TagReadsGRDB(database: database)
        let tagAutocompleteHandler = TagAutocompleteHandler(store: tagReads)
        let listTagsHandler = ListTagsHandler(store: tagReads)
        let archiveTagHandler = ArchiveTagHandler(eventStore: eventStore, ids: ids)
        let unarchiveTagHandler = UnarchiveTagHandler(eventStore: eventStore, ids: ids)
        let captureHandler = CaptureEntryHandler(
            eventStore: eventStore,
            ids: ids,
            tagIdLookup: tagsPublishedReads
        )
        let moveHandler = MoveEntryHandler(eventStore: eventStore, ids: ids)
        let scheduleHandler = ScheduleEntryHandler(eventStore: eventStore, ids: ids)
        let setEntryTagsHandler = SetEntryTagsHandler(
            eventStore: eventStore,
            ids: ids,
            tagIdLookup: tagsPublishedReads
        )
        let entryReads = EntryReadsGRDB(database: database)
        let listRecentHandler = ListRecentEntriesHandler(store: entryReads)
        let findEntriesHandler = FindEntriesHandler(store: entryReads)
        let listDueEntriesHandler = ListDueEntriesHandler(store: entryReads)
        let listLatestEntriesHandler = ListLatestEntriesHandler(store: entryReads)
        let getEntryHandler = GetEntryHandler(store: entryReads)
        let getEntryStatsHandler = GetEntryStatsHandler(store: entryReads)

        self.database = database
        self.clock = clock
        self.ids = ids
        self.deviceId = deviceId
        self.projector = projector
        self.eventStore = eventStore
        self.tagsPublishedReads = tagsPublishedReads
        self.tagReads = tagReads
        self.tagAutocompleteHandler = tagAutocompleteHandler
        self.listTagsHandler = listTagsHandler
        self.archiveTagHandler = archiveTagHandler
        self.unarchiveTagHandler = unarchiveTagHandler
        self.captureHandler = captureHandler
        self.moveHandler = moveHandler
        self.scheduleHandler = scheduleHandler
        self.setEntryTagsHandler = setEntryTagsHandler
        self.entryReads = entryReads
        self.listRecentHandler = listRecentHandler
        self.findEntriesHandler = findEntriesHandler
        self.listDueEntriesHandler = listDueEntriesHandler
        self.listLatestEntriesHandler = listLatestEntriesHandler
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
        self.dispatchEntries = { [listRecentHandler, findEntriesHandler, listDueEntriesHandler] limit, scope, filter, before in
            switch filter {
            case .none:
                return try await listRecentHandler.handle(
                    ListRecentEntriesQuery(limit: limit, scope: scope, before: before, includeOverdue: true)
                )
            case .recentCollapsed(let overdueBefore):
                return try await listRecentHandler.handle(
                    ListRecentEntriesQuery(
                        limit: limit,
                        scope: scope,
                        before: before,
                        includeOverdue: false,
                        overdueBeforeMillis: overdueBefore
                    )
                )
            case .due:
                // The agenda is one bounded page ordered by due date; created-at pagination doesn't
                // apply, so a paged (before != nil) request has nothing further to return.
                guard before == nil else { return [] }
                return try await listDueEntriesHandler.handle(ListDueEntriesQuery(limit: 200))
            case .find(let text, let tags):
                // An empty /find filter is just a recent listing; route it through the same handler as
                // .none so the two paths can't drift.
                if (text?.isEmpty ?? true) && tags.isEmpty {
                    return try await listRecentHandler.handle(
                        ListRecentEntriesQuery(limit: limit, scope: scope, before: before)
                    )
                }
                return try await findEntriesHandler.handle(
                    FindEntriesQuery(text: text, tagNames: tags, scope: scope, limit: limit, before: before)
                )
            }
        }
        self.dispatchLatest = { [listLatestEntriesHandler] limit in
            try await listLatestEntriesHandler.handle(ListLatestEntriesQuery(limit: limit))
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
        self.dispatchSchedule = { [scheduleHandler, clock, deviceId] entryId, dueAt in
            let cmd = ScheduleEntryCommand(
                entryId: entryId,
                dueAt: dueAt,
                deviceId: deviceId,
                now: clock.now()
            )
            try await scheduleHandler.handle(cmd)
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
        self.dispatchTagSuggestions = { [tagAutocompleteHandler] prefix, limit in
            try await tagAutocompleteHandler.handle(
                TagAutocompleteQuery(prefix: prefix, limit: limit)
            )
        }
        self.dispatchSetEntryTags = { [setEntryTagsHandler, clock, deviceId] entryId, toAdd, toRemove in
            let cmd = SetEntryTagsCommand(
                entryId: entryId,
                toAdd: toAdd,
                toRemove: toRemove,
                deviceId: deviceId,
                now: clock.now()
            )
            try await setEntryTagsHandler.handle(cmd)
        }
        self.dispatchListTags = { [listTagsHandler] prefix, limit in
            try await listTagsHandler.handle(ListTagsQuery(prefix: prefix, limit: limit))
        }
        self.dispatchArchiveTag = { [archiveTagHandler, clock, deviceId] tagId in
            let cmd = ArchiveTagCommand(tagId: tagId, deviceId: deviceId, now: clock.now())
            try await archiveTagHandler.handle(cmd)
        }
        self.dispatchUnarchiveTag = { [unarchiveTagHandler, clock, deviceId] tagId in
            let cmd = UnarchiveTagCommand(tagId: tagId, deviceId: deviceId, now: clock.now())
            try await unarchiveTagHandler.handle(cmd)
        }
        #if DEBUG
        self.dispatchSeedCapture = { [captureHandler, deviceId] text, at in
            let cmd = CaptureEntryCommand(rawText: text, deviceId: deviceId, now: at)
            _ = try? await captureHandler.handle(cmd)
        }
        #endif
    }
}
