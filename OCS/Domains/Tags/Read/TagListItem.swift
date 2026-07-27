import Foundation

nonisolated struct TagListItem: Sendable, Equatable {
    let id: UUID
    let name: String
    let usageCount: Int
}
