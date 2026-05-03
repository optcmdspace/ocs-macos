import Foundation

nonisolated struct MoveEntryCommand: Sendable {
    let entryId: UUID
    let toBin: Bin
    let deviceId: UUID
    let now: Date
}
