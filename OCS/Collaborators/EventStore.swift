import Foundation

protocol EventStore: Sendable {
    /// All-or-nothing: on success events are durable and projections visible; on throw, no state changed.
    nonisolated func append(_ events: [any DomainEvent]) async throws
}
