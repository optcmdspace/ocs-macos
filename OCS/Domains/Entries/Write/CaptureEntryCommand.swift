import Foundation

nonisolated struct CaptureEntryCommand: Sendable {
    let rawText: String
    let deviceId: UUID
    let now: Date
}
