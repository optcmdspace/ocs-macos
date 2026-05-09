import Foundation

@MainActor
final class TagAutocompleteCoordinator {
    struct AcceptResult {
        let text: String
        let cursor: Int
    }

    private let windowSize: Int
    private let getPage: () -> CapturePageMode
    private let setPage: (CapturePageMode) -> Void
    private let onHeightChange: () -> Void
    private let loader: TagSuggestionsLoader

    init(
        dispatch: @escaping DispatchTagSuggestions,
        windowSize: Int,
        getPage: @escaping () -> CapturePageMode,
        setPage: @escaping (CapturePageMode) -> Void,
        onHeightChange: @escaping () -> Void
    ) {
        self.windowSize = windowSize
        self.getPage = getPage
        self.setPage = setPage
        self.onHeightChange = onHeightChange
        self.loader = TagSuggestionsLoader(dispatch: dispatch)
    }

    func cancel() {
        loader.cancel()
    }

    // True when the cursor sits inside a `#tag` token; the caller should skip its slash-suggestion fallback.
    func handleFieldChange(raw: String, cursor: Int) -> Bool {
        guard let token = HashtagSyntax.activeTagToken(in: raw, at: cursor) else {
            loader.cancel()
            return false
        }
        kickoff(prefix: token.prefix, location: token.location, length: token.length)
        return true
    }

    func navigate(_ direction: CaptureNavDirection, in state: TagSuggestionState) -> Bool {
        guard !state.list.isEmpty else { return true }
        let next: TagSuggestionState
        switch direction {
        case .down: next = state.cursorDown()
        case .up: next = state.cursorUp()
        case .pageDown: next = state.pageDown()
        case .pageUp: next = state.pageUp()
        }
        setPage(.tagSuggestions(next))
        return true
    }

    func acceptSelection(_ pick: TagSuggestion, state: TagSuggestionState, currentText: String) -> AcceptResult {
        let raw = currentText as NSString
        let replacement = "#\(pick.name) "
        let beforeRange = NSRange(location: 0, length: state.tokenLocation)
        let afterStart = state.tokenLocation + state.tokenLength
        let before = raw.substring(with: beforeRange)
        let after = afterStart < raw.length ? raw.substring(from: afterStart) : ""
        let cursor = state.tokenLocation + (replacement as NSString).length
        loader.cancel()
        setPage(.idle)
        return AcceptResult(text: before + replacement + after, cursor: cursor)
    }

    private func kickoff(prefix: String, location: Int, length: Int) {
        let baseline = TagSuggestionState.empty(
            windowSize: windowSize,
            prefix: prefix,
            tokenLocation: location,
            tokenLength: length
        )
        if case .tagSuggestions(let existing) = getPage(),
           existing.prefix == prefix,
           existing.tokenLocation == location,
           existing.tokenLength == length {
            // Same context, fetch in flight; don't blank the visible items.
        } else {
            setPage(.tagSuggestions(baseline))
        }
        let getPage = self.getPage
        let setPage = self.setPage
        let onHeightChange = self.onHeightChange
        loader.load(prefix: prefix) { items in
            guard case .tagSuggestions(let current) = getPage(),
                  current.prefix == prefix,
                  current.tokenLocation == location,
                  current.tokenLength == length else { return }
            setPage(.tagSuggestions(current.replacing(items: items)))
            onHeightChange()
        }
    }
}
