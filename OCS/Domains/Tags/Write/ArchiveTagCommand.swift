import Foundation

nonisolated struct ArchiveTagCommand: Sendable {
    let tagId: UUID
    let deviceId: UUID
    let now: Date
}
