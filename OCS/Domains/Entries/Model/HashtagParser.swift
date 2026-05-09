import Foundation

nonisolated struct ParsedCapture: Sendable, Equatable {
    let body: String
    let tags: [TagName]
}

nonisolated enum HashtagParser {
    static func parse(_ raw: String) -> ParsedCapture {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        var tags: [TagName] = []
        var seen: Set<TagName> = []
        var bodyTokens: [String] = []
        for token in trimmed.split(whereSeparator: { $0.isWhitespace }) {
            if token.hasPrefix("#") {
                let afterHash = token.dropFirst()
                let namePart = afterHash.prefix(while: { $0.isLetter || $0.isNumber })
                if let name = TagName(String(namePart)) {
                    if seen.insert(name).inserted { tags.append(name) }
                    continue
                }
            }
            bodyTokens.append(String(token))
        }
        return ParsedCapture(body: bodyTokens.joined(separator: " "), tags: tags)
    }
}
