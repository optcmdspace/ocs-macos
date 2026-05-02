import Foundation

nonisolated struct EntryCaptured: DomainEvent {
    let id: UUID
    let entryId: UUID
    let text: String
    let deviceId: UUID
    let createdAt: Date
}
