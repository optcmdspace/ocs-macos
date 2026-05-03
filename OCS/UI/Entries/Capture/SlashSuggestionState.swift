import Foundation

struct SlashSuggestionState: Equatable {
    let items: [SlashCommand.Spec]
    let selectedIndex: Int

    static let empty = SlashSuggestionState(items: [], selectedIndex: 0)

    var isEmpty: Bool { items.isEmpty }

    var selected: SlashCommand.Spec? {
        guard selectedIndex >= 0, selectedIndex < items.count else { return nil }
        return items[selectedIndex]
    }

    func applying(text: String) -> SlashSuggestionState {
        let next = SlashCommand.suggestions(for: text)
        if next.isEmpty { return .empty }
        let index = next == items ? min(selectedIndex, next.count - 1) : 0
        return SlashSuggestionState(items: next, selectedIndex: index)
    }

    func movedDown() -> SlashSuggestionState {
        guard !items.isEmpty else { return self }
        return SlashSuggestionState(items: items, selectedIndex: min(selectedIndex + 1, items.count - 1))
    }

    func movedUp() -> SlashSuggestionState {
        guard !items.isEmpty else { return self }
        return SlashSuggestionState(items: items, selectedIndex: max(selectedIndex - 1, 0))
    }
}
