import Foundation

protocol TagIDLookup: Sendable {
    nonisolated func activeIds(forNames names: [TagName]) async throws -> [TagName: UUID]
}
