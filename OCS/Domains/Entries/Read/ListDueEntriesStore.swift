import Foundation

protocol ListDueEntriesStore: Sendable {
    nonisolated func dueEntries(limit: Int) async throws -> [EntryListItem]
}
