import Foundation

nonisolated enum SlashCommand {
    case capture(String)
    case find(text: String?, tags: [TagName], scope: ListRecentEntriesQuery.Scope)
    case setSound(Bool)

    nonisolated struct Spec: Sendable, Equatable {
        // What the row shows ("/find", "/set" at the top; "sound" once you've descended into /set).
        let display: String
        // What gets written to the field when the suggestion is picked. Includes the full path
        // so we don't have to know the user's current cursor position to splice it in.
        let token: String
        let description: String
    }

    // Adding a slash command means three local edits in this file:
    //   1. add a case to SlashCommand,
    //   2. add a Node to `tree` (and any nested Nodes),
    //   3. add a Verb entry below with its parser.
    // No other file in the codebase needs to grow.

    // Range of the leading "/<verb>" token when it prefixes a known catalog command. Returns nil
    // when the field doesn't start with a command — used for input-field highlighting and the
    // cursor-tint switch.
    nonisolated static func leadingCommandRange(in raw: String) -> NSRange? {
        let nsRaw = raw as NSString
        var start = 0
        while start < nsRaw.length, isWhitespace(nsRaw.character(at: start)) { start += 1 }
        guard start < nsRaw.length, nsRaw.character(at: start) == 0x2F /* '/' */ else { return nil }
        var end = start + 1
        while end < nsRaw.length, !isWhitespace(nsRaw.character(at: end)) { end += 1 }
        let token = nsRaw.substring(with: NSRange(location: start, length: end - start))
        guard !suggestions(for: token).isEmpty else { return nil }
        return NSRange(location: start, length: end - start)
    }

    private nonisolated static func isWhitespace(_ c: unichar) -> Bool {
        guard let scalar = UnicodeScalar(c) else { return false }
        return CharacterSet.whitespacesAndNewlines.contains(scalar)
    }

    nonisolated static func suggestions(for raw: String) -> [Spec] {
        guard let context = parseContext(raw) else { return [] }
        if context.segments.isEmpty {
            return topLevelSpecs
        }

        var nodes = tree
        var prefix = "/"
        for (idx, seg) in context.segments.enumerated() {
            let isLast = idx == context.segments.count - 1
            if isLast && !context.endsWithSpace {
                return nodes
                    .filter { $0.label.hasPrefix(seg) }
                    .map { specFor($0, parentPrefix: prefix) }
            }
            guard let node = nodes.first(where: { $0.label == seg }) else { return [] }
            prefix += node.label + " "
            nodes = node.children
            if nodes.isEmpty { return [] }
        }
        return nodes.map { specFor($0, parentPrefix: prefix) }
    }

    nonisolated static func parse(_ raw: String) -> SlashCommand {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let parts = trimmed.split(whereSeparator: { $0.isWhitespace }).map { String($0) }
        guard let head = parts.first?.lowercased() else { return .capture(trimmed) }
        let args = Array(parts.dropFirst())
        for verb in Verb.all where verb.token == head {
            if let cmd = verb.parse(args) { return cmd }
        }
        return .capture(trimmed)
    }

    private nonisolated struct Node: Sendable {
        let label: String
        let description: String
        let children: [Node]
    }

    private nonisolated static let tree: [Node] = [
        Node(
            label: "find",
            description: "search by text and/or #tag",
            children: []
        ),
        Node(
            label: "set",
            description: "change a setting",
            children: [
                Node(label: "sound", description: "on/off — tick on save", children: []),
            ]
        ),
    ]

    private nonisolated static let topLevelSpecs: [Spec] = tree.map {
        specFor($0, parentPrefix: "/")
    }

    private nonisolated static func specFor(_ node: Node, parentPrefix: String) -> Spec {
        let display = parentPrefix == "/" ? "/" + node.label : node.label
        // Trailing space lands the cursor where the next segment goes.
        let token = parentPrefix + node.label + " "
        return Spec(display: display, token: token, description: node.description)
    }

    private struct Context {
        let segments: [String]
        let endsWithSpace: Bool
    }

    private nonisolated static func parseContext(_ raw: String) -> Context? {
        let leadingTrimmed = raw.drop(while: { $0.isWhitespace })
        guard leadingTrimmed.first == "/" else { return nil }
        let body = leadingTrimmed.dropFirst()
        let segments = body
            .split(whereSeparator: { $0.isWhitespace })
            .map { $0.lowercased() }
        let endsWithSpace = body.last?.isWhitespace ?? false
        return Context(segments: segments, endsWithSpace: endsWithSpace)
    }

    private nonisolated struct Verb: Sendable {
        let token: String
        let parse: @Sendable (_ args: [String]) -> SlashCommand?

        nonisolated static let all: [Verb] = [
            Verb(token: "/find", parse: parseFind),
            Verb(token: "/set", parse: parseSet),
        ]
    }

    @Sendable nonisolated private static func parseFind(_ args: [String]) -> SlashCommand? {
        let rest = args.joined(separator: " ")
        let parsed = HashtagParser.parse(rest)
        let text: String? = parsed.body.isEmpty ? nil : parsed.body
        return .find(text: text, tags: parsed.tags, scope: .all)
    }

    @Sendable nonisolated private static func parseSet(_ args: [String]) -> SlashCommand? {
        let key = args.first?.lowercased() ?? ""
        let rest = Array(args.dropFirst())
        switch key {
        case "sound":
            return parseSetSound(rest)
        default:
            return nil
        }
    }

    nonisolated private static func parseSetSound(_ args: [String]) -> SlashCommand? {
        let value = args.first?.lowercased() ?? ""
        switch value {
        case "on":  return .setSound(true)
        case "off": return .setSound(false)
        default:    return nil
        }
    }
}
