import Foundation

nonisolated final class SystemClock: Clock {
    func now() -> Date { Date() }
}
