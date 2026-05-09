import Foundation

nonisolated enum SlashCommand {
    case capture(String)
    case list(ListRecentEntriesQuery.Scope)
    case listByTag(ListRecentEntriesQuery.Scope, TagName)
    case sound(Bool)

    nonisolated struct Spec: Sendable, Equatable {
        let token: String
        let description: String
    }

    nonisolated static let catalog: [Spec] = [
        Spec(token: "/list", description: "show active captures"),
        Spec(token: "/list all", description: "show all captures, including done"),
        Spec(token: "/list #", description: "filter by tag, e.g. /list #grocery"),
        Spec(token: "/sound on", description: "play a tick on save"),
        Spec(token: "/sound off", description: "no sound on save"),
    ]

    nonisolated static func suggestions(for raw: String) -> [Spec] {
        let trimmed = raw.trimmingCharacters(in: .whitespaces)
        guard trimmed.hasPrefix("/") else { return [] }
        let lower = trimmed.lowercased()
        if lower == "/" { return catalog }
        return catalog.filter { $0.token.lowercased().hasPrefix(lower) }
    }

    nonisolated static func parse(_ raw: String) -> SlashCommand {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let parts = trimmed.split(whereSeparator: { $0.isWhitespace }).map { String($0).lowercased() }
        if parts == ["/list"] { return .list(.active) }
        if parts == ["/list", "all"] { return .list(.all) }
        if parts == ["/sound", "on"] { return .sound(true) }
        if parts == ["/sound", "off"] { return .sound(false) }
        if parts.count == 2, parts[0] == "/list", parts[1].hasPrefix("#") {
            if let name = TagName(String(parts[1].dropFirst())) {
                return .listByTag(.active, name)
            }
        }
        if parts.count == 3, parts[0] == "/list", parts[1] == "all", parts[2].hasPrefix("#") {
            if let name = TagName(String(parts[2].dropFirst())) {
                return .listByTag(.all, name)
            }
        }
        return .capture(trimmed)
    }
}
