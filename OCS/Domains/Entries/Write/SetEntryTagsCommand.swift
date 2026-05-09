import Foundation

nonisolated struct SetEntryTagsCommand: Sendable {
    let entryId: UUID
    let toAdd: [TagName]
    let toRemove: [TagName]
    let deviceId: UUID
    let now: Date
}
