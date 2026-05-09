import Foundation

nonisolated struct TagSuggestion: Sendable, Equatable {
    let name: String
    let usageCount: Int
}
