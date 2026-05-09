import Foundation

protocol TagAutocompleteStore: Sendable {
    nonisolated func suggestions(prefix: String, limit: Int) async throws -> [TagSuggestion]
}
