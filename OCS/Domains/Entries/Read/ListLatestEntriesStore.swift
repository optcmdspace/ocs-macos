import Foundation

protocol ListLatestEntriesStore: Sendable {
    nonisolated func latestEntries(limit: Int) async throws -> [EntryListItem]
}
