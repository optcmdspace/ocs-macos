import Foundation

nonisolated struct EntryListItem: Sendable, Equatable {
    let id: UUID
    let text: String
    let bin: Bin
    let createdAt: Date
    let dueAt: Date?
    let tags: [String]
}
