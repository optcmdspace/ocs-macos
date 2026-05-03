import Foundation

nonisolated enum Bin: String, Sendable, Codable, Equatable, CaseIterable {
    case inbox
    case next
    case waiting
    case someday
    case reference
    case done
    case trash
}
