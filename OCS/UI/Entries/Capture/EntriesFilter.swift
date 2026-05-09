import Foundation

nonisolated enum EntriesFilter: Sendable, Equatable {
    case none
    case find(text: String?, tags: [TagName])
}
