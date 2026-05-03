import Foundation

nonisolated struct SlashSuggestionState: Sendable, Equatable {
    let list: TerminalListState<SlashCommand.Spec>

    static func empty(windowSize: Int) -> SlashSuggestionState {
        SlashSuggestionState(list: TerminalListState(windowSize: windowSize))
    }

    var isEmpty: Bool { list.isEmpty }
    var selected: SlashCommand.Spec? { list.selected }

    func applying(text: String) -> SlashSuggestionState {
        let next = SlashCommand.suggestions(for: text)
        if next.isEmpty {
            return SlashSuggestionState(list: TerminalListState(windowSize: list.windowSize))
        }
        if next == list.items {
            return self
        }
        return SlashSuggestionState(list: TerminalListState(items: next, windowSize: list.windowSize))
    }

    func cursorDown() -> Self { Self(list: list.cursorDown()) }
    func cursorUp() -> Self { Self(list: list.cursorUp()) }
    func pageDown() -> Self { Self(list: list.pageDown()) }
    func pageUp() -> Self { Self(list: list.pageUp()) }
}
