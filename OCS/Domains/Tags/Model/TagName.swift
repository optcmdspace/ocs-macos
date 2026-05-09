import Foundation

nonisolated struct TagName: Sendable, Codable, Equatable, Hashable {
    let value: String

    init?(_ raw: String) {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty, trimmed.count <= 64 else { return nil }
        guard trimmed.unicodeScalars.allSatisfy({ CharacterSet.alphanumerics.contains($0) }) else { return nil }
        self.value = trimmed
    }
}
