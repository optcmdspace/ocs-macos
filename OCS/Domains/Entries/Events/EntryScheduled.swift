import Foundation

nonisolated struct EntryScheduled: DomainEvent {
    let id: UUID
    let entryId: UUID
    let dueAt: Date?
    let deviceId: UUID
    let createdAt: Date
}
