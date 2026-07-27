import Foundation

nonisolated struct TagArchived: DomainEvent {
    let id: UUID
    let tagId: UUID
    let deviceId: UUID
    let createdAt: Date
}
