import Foundation

nonisolated struct EntryUntagged: DomainEvent {
    let id: UUID
    let entryId: UUID
    let tagId: UUID
    let deviceId: UUID
    let createdAt: Date
}
