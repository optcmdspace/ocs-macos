import Foundation

typealias DispatchTagSuggestions = @Sendable (_ prefix: String, _ limit: Int) async throws -> [TagSuggestion]
typealias DispatchSetEntryTags = @Sendable (_ entryId: UUID, _ toAdd: [TagName], _ toRemove: [TagName]) async throws -> Void
