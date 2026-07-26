import Foundation

// Raw ranges of the trailing date phrase, for input highlighting. Strips tags like HashtagParser and
// reuses DueDateParser.match, so the highlight never drifts from what a capture would consume.
nonisolated enum DueDateSyntax {
    static func tokenRanges(in raw: String, now: Date, calendar: Calendar = .current) -> [NSRange] {
        let nsRaw = raw as NSString
        var wordRanges: [NSRange] = []
        var words: [String] = []
        var i = 0
        let length = nsRaw.length
        while i < length {
            if isWhitespace(nsRaw.character(at: i)) { i += 1; continue }
            let start = i
            while i < length, !isWhitespace(nsRaw.character(at: i)) { i += 1 }
            let range = NSRange(location: start, length: i - start)
            let token = nsRaw.substring(with: range)
            if isTagToken(token) { continue }
            wordRanges.append(range)
            words.append(token.lowercased())
        }
        guard let m = DueDateParser.match(words, now: now, calendar: calendar) else { return [] }
        // Mirror the parser's rule: a phrase that would empty the body is left as plain text, so don't
        // highlight it either ("tomorrow" on its own is not a date).
        guard words.count > m.length else { return [] }
        return Array(wordRanges.suffix(m.length))
    }

    // A tag token: '#' plus a valid tag name, like HashtagParser.parse.
    private static func isTagToken(_ token: String) -> Bool {
        guard token.hasPrefix("#") else { return false }
        let namePart = token.dropFirst().prefix(while: { $0.isLetter || $0.isNumber })
        return !namePart.isEmpty && TagName(String(namePart)) != nil
    }

    private static func isWhitespace(_ c: unichar) -> Bool {
        guard let scalar = UnicodeScalar(c) else { return false }
        return CharacterSet.whitespacesAndNewlines.contains(scalar)
    }
}
