import Foundation

nonisolated struct UnarchiveTagCommand: Sendable {
    let tagId: UUID
    let deviceId: UUID
    let now: Date
}
