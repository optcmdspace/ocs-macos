import Foundation

nonisolated struct TagCreated: DomainEvent {
    let id: UUID
    let tagId: UUID
    let name: String
    let deviceId: UUID
    let createdAt: Date
}
