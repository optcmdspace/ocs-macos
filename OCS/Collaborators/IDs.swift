import Foundation

protocol IDs: Sendable {
    nonisolated func next() -> UUID
}
