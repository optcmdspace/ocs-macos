import Foundation

protocol Clock: Sendable {
    nonisolated func now() -> Date
}
