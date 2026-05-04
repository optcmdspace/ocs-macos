import Foundation

protocol GetEntryStore: Sendable {
    nonisolated func entry(id: UUID) async throws -> EntryListItem?
}
