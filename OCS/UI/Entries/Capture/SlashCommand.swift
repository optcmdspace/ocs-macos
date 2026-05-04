import Foundation

nonisolated enum SlashCommand {
    case capture(String)
    case list(ListRecentEntriesQuery.Scope)
    case sound(Bool)

    nonisolated struct Spec: Sendable, Equatable {
        let token: String
        let description: String
    }

    nonisolated static let catalog: [Spec] = [
        Spec(token: "/list", description: "show active captures"),
        Spec(token: "/list all", description: "show all captures, including done"),
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
        switch parts {
        case ["/list"]:
            return .list(.active)
        case ["/list", "all"]:
            return .list(.all)
        case ["/sound", "on"]:
            return .sound(true)
        case ["/sound", "off"]:
            return .sound(false)
        default:
            return .capture(trimmed)
        }
    }
}
