import Foundation

protocol DomainEvent: Sendable, Codable, Equatable {
    nonisolated var id: UUID { get }
    nonisolated var deviceId: UUID { get }
    nonisolated var createdAt: Date { get }
}
