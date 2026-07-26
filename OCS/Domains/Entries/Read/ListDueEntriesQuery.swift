import Foundation

// Entries carrying a due date, for the grouped agenda view. Ordered soonest-due first by the store.
nonisolated struct ListDueEntriesQuery: Sendable {
    let limit: Int
}
