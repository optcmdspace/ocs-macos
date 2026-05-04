import Foundation

// Day-count thresholds drive both row aging visuals and the stats query stale cutoff.
nonisolated enum AgingThresholds {
    static let entryAgedAfterDays: Int = 3
    static let entryStaleAfterDays: Int = 7
    static let entryAgedAfterSeconds: TimeInterval = TimeInterval(entryAgedAfterDays * 86_400)
    static let entryStaleAfterSeconds: TimeInterval = TimeInterval(entryStaleAfterDays * 86_400)
}
