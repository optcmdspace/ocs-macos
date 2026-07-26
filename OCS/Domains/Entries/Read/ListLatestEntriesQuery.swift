import Foundation

// The most recently captured active entries
nonisolated struct ListLatestEntriesQuery: Sendable {
    let limit: Int
}
