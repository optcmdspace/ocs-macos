import Foundation

protocol GetEntryStatsStore: Sendable {
    nonisolated func entryStats(
        todayStartMillis: Int64,
        yesterdayStartMillis: Int64,
        staleCutoffMillis: Int64
    ) async throws -> EntryStats
}
