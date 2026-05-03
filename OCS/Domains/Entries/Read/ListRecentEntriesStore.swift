import Foundation

protocol ListRecentEntriesStore: Sendable {
    nonisolated func recentEntries(limit: Int) async throws -> [EntryListItem]
}
