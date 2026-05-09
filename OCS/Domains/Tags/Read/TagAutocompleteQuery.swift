import Foundation

nonisolated struct TagAutocompleteQuery: Sendable {
    let prefix: String
    let limit: Int
}
