import Foundation

nonisolated enum Bin: String, Sendable, Codable, Equatable, CaseIterable {
    case inbox
    case waiting
    case reference
    case done
    case trash
}
