import Foundation

nonisolated struct EntryMoved: DomainEvent {
    let id: UUID
    let entryId: UUID
    let toBin: Bin
    let deviceId: UUID
    let createdAt: Date
}
