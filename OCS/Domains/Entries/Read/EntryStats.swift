import Foundation

nonisolated struct EntryStats: Sendable, Equatable {
    let todayCount: Int
    let yesterdayCount: Int
    let activeCount: Int
    let staleActiveCount: Int
}
