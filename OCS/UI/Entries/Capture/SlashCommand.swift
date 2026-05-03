import Foundation

enum SlashCommand {
    case capture(String)
    case list

    struct Spec: Sendable, Equatable {
        let token: String
        let description: String
    }

    static let catalog: [Spec] = [
        Spec(token: "/list", description: "show recent captures"),
    ]

    static func suggestions(for raw: String) -> [Spec] {
        let trimmed = raw.trimmingCharacters(in: .whitespaces)
        guard trimmed.hasPrefix("/"), !trimmed.contains(" ") else { return [] }
        let lower = trimmed.lowercased()
        if lower == "/" { return catalog }
        return catalog.filter { $0.token.lowercased().hasPrefix(lower) }
    }

    static func parse(_ raw: String) -> SlashCommand {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        switch trimmed.lowercased() {
        case "/list":
            return .list
        default:
            return .capture(trimmed)
        }
    }
}
