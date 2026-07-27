import Foundation

protocol ListTagsStore: Sendable {
    nonisolated func listTags(prefix: String, limit: Int) async throws -> [TagListItem]
}
