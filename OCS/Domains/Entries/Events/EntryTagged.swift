import Foundation

nonisolated struct EntryTagged: DomainEvent {
    let id: UUID
    let entryId: UUID
    let tagId: UUID
    let deviceId: UUID
    let createdAt: Date
}
