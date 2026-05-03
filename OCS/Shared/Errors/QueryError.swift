import Foundation

nonisolated enum QueryError: Error, Sendable {
    case notFound(UUID)
    case storage(underlying: Error)
}
