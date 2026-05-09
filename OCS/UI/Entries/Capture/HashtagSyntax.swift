import Foundation

nonisolated enum HashtagSyntax {
    nonisolated struct ActiveTagToken: Sendable, Equatable {
        let prefix: String
        let location: Int
        let length: Int
    }

    // Trailing non-alphanumerics (e.g. punctuation in `#urgent.`) are excluded so the highlight matches what HashtagParser.parse(_:) records.
    static func tokenRanges(in raw: String) -> [NSRange] {
        let nsRaw = raw as NSString
        var ranges: [NSRange] = []
        var i = 0
        let length = nsRaw.length
        while i < length {
            if isWhitespace(nsRaw.character(at: i)) { i += 1; continue }
            let tokenStart = i
            while i < length, !isWhitespace(nsRaw.character(at: i)) { i += 1 }
            let tokenEnd = i
            if tokenEnd - tokenStart >= 2, nsRaw.character(at: tokenStart) == 0x23 /* '#' */ {
                var j = tokenStart + 1
                while j < tokenEnd, isAlphanumeric(nsRaw.character(at: j)) { j += 1 }
                if j > tokenStart + 1 {
                    let nameLength = j - tokenStart - 1
                    let candidate = nsRaw.substring(with: NSRange(location: tokenStart + 1, length: nameLength))
                    if TagName(candidate) != nil {
                        ranges.append(NSRange(location: tokenStart, length: nameLength + 1))
                    }
                }
            }
        }
        return ranges
    }

    // Drives autocomplete: returns the `#<alphanum>` token containing the cursor (prefix may be empty when cursor sits just after `#`).
    static func activeTagToken(in raw: String, at cursorOffset: Int) -> ActiveTagToken? {
        let nsRaw = raw as NSString
        var i = 0
        let length = nsRaw.length
        while i < length {
            if isWhitespace(nsRaw.character(at: i)) { i += 1; continue }
            let tokenStart = i
            while i < length, !isWhitespace(nsRaw.character(at: i)) { i += 1 }
            let tokenEnd = i
            if cursorOffset >= tokenStart, cursorOffset <= tokenEnd {
                guard tokenEnd > tokenStart, nsRaw.character(at: tokenStart) == 0x23 /* '#' */ else { return nil }
                var j = tokenStart + 1
                while j < tokenEnd, isAlphanumeric(nsRaw.character(at: j)) { j += 1 }
                guard cursorOffset <= j else { return nil }
                let prefixLength = j - tokenStart - 1
                let prefix = nsRaw.substring(with: NSRange(location: tokenStart + 1, length: prefixLength))
                return ActiveTagToken(prefix: prefix, location: tokenStart, length: prefixLength + 1)
            }
        }
        return nil
    }

    private static func isWhitespace(_ c: unichar) -> Bool {
        guard let scalar = UnicodeScalar(c) else { return false }
        return CharacterSet.whitespacesAndNewlines.contains(scalar)
    }

    private static func isAlphanumeric(_ c: unichar) -> Bool {
        guard let scalar = UnicodeScalar(c) else { return false }
        return CharacterSet.alphanumerics.contains(scalar)
    }
}
