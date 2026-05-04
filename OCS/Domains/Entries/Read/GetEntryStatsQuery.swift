import Foundation

// Cutoffs are caller-supplied so the user's local calendar stays in the UI layer.
nonisolated struct GetEntryStatsQuery: Sendable {
    let todayStartMillis: Int64
    let yesterdayStartMillis: Int64
    let staleCutoffMillis: Int64
}
