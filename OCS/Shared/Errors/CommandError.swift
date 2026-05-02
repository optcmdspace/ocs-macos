import Foundation

nonisolated enum CommandError: Error, Sendable {
    case validationFailed(String)
    case notFound(UUID)
    case conflict(String)
    case storage(underlying: Error)
}
