import Foundation

nonisolated struct EntryListItem: Sendable, Equatable {
    let id: UUID
    let text: String
    let createdAt: Date
}
