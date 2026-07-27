import Foundation

nonisolated struct TagUnarchived: DomainEvent {
    let id: UUID
    let tagId: UUID
    let deviceId: UUID
    let createdAt: Date
}
