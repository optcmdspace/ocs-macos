import Foundation

nonisolated struct ScheduleEntryCommand: Sendable {
    let entryId: UUID
    let dueAt: Date?
    let deviceId: UUID
    let now: Date
}
