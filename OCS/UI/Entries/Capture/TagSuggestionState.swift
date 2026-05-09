import Foundation

nonisolated struct TagSuggestionState: Sendable, Equatable {
    let list: TerminalListState<TagSuggestion>
    let prefix: String
    let tokenLocation: Int
    let tokenLength: Int

    static func empty(windowSize: Int, prefix: String, tokenLocation: Int, tokenLength: Int) -> TagSuggestionState {
        TagSuggestionState(
            list: TerminalListState(windowSize: windowSize),
            prefix: prefix,
            tokenLocation: tokenLocation,
            tokenLength: tokenLength
        )
    }

    var isEmpty: Bool { list.isEmpty }
    var selected: TagSuggestion? { list.selected }

    func replacing(items: [TagSuggestion]) -> TagSuggestionState {
        TagSuggestionState(
            list: TerminalListState(items: items, windowSize: list.windowSize),
            prefix: prefix,
            tokenLocation: tokenLocation,
            tokenLength: tokenLength
        )
    }

    func cursorDown() -> Self { with(list: list.cursorDown()) }
    func cursorUp() -> Self { with(list: list.cursorUp()) }
    func pageDown() -> Self { with(list: list.pageDown()) }
    func pageUp() -> Self { with(list: list.pageUp()) }

    private func with(list newList: TerminalListState<TagSuggestion>) -> TagSuggestionState {
        TagSuggestionState(
            list: newList,
            prefix: prefix,
            tokenLocation: tokenLocation,
            tokenLength: tokenLength
        )
    }
}
