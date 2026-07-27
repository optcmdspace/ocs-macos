import AppKit

@MainActor
final class TagEditCoordinator {
    // Load all tags once; the editor filters in memory, not with a query per keystroke.
    private static let suggestionLimit = 500

    private let dispatchSuggestions: DispatchTagSuggestions
    private let dispatchSetTags: DispatchSetEntryTags
    private let onChange: () -> Void
    private let onCommit: (UUID, Set<String>) -> Void

    private(set) var state: TagEditState?

    init(
        dispatchSuggestions: @escaping DispatchTagSuggestions,
        dispatchSetTags: @escaping DispatchSetEntryTags,
        onChange: @escaping () -> Void,
        onCommit: @escaping (UUID, Set<String>) -> Void
    ) {
        self.dispatchSuggestions = dispatchSuggestions
        self.dispatchSetTags = dispatchSetTags
        self.onChange = onChange
        self.onCommit = onCommit
    }

    var isActive: Bool { state != nil }

    func enter(for item: EntryListItem) {
        let originalApplied = Set(item.tags)
        let entryId = item.id
        let dispatch = dispatchSuggestions
        Task { [weak self] in
            let suggestions = (try? await dispatch("", Self.suggestionLimit)) ?? []
            await MainActor.run {
                guard let self else { return }
                let initialCursor = suggestions.firstIndex(where: { originalApplied.contains($0.name) }) ?? 0
                self.state = TagEditState(
                    entryId: entryId,
                    availableTags: suggestions,
                    addedTags: [],
                    originalApplied: originalApplied,
                    currentApplied: originalApplied,
                    cursor: initialCursor,
                    query: ""
                )
                self.onChange()
            }
        }
    }

    func exit(commit: Bool) {
        guard let state else { return }
        self.state = nil
        onChange()
        guard commit, state.hasChanges else { return }
        let toAdd = state.diff.toAdd.compactMap(TagName.init)
        let toRemove = state.diff.toRemove.compactMap(TagName.init)
        let entryId = state.entryId
        let appliedNames = state.currentApplied
        let dispatch = dispatchSetTags
        let onCommit = self.onCommit
        Task {
            do {
                try await dispatch(entryId, toAdd, toRemove)
                await MainActor.run { onCommit(entryId, appliedNames) }
            } catch {
                NSLog("OCS: set entry tags failed: %@", String(describing: error))
            }
        }
    }

    // Returns true when the event was consumed.
    func handleKey(_ event: NSEvent) -> Bool {
        guard var current = state else { return false }
        switch event.keyCode {
        case CaptureKeyCodes.esc:
            if !current.query.isEmpty {
                current.clearQuery()
                state = current
                onChange()
            } else {
                exit(commit: false)
            }
            return true
        case CaptureKeyCodes.returnKey, CaptureKeyCodes.numpadEnter:
            exit(commit: true)
            return true
        case CaptureKeyCodes.leftArrow:
            current.cursorLeft()
            state = current
            onChange()
            return true
        case CaptureKeyCodes.rightArrow:
            current.cursorRight()
            state = current
            onChange()
            return true
        case CaptureKeyCodes.space:
            current.selectFocused()
            state = current
            onChange()
            return true
        case CaptureKeyCodes.backspace:
            current.backspaceQuery()
            state = current
            onChange()
            return true
        default:
            break
        }
        let chars = event.charactersIgnoringModifiers ?? ""
        guard let scalar = chars.unicodeScalars.first,
              CharacterSet.alphanumerics.contains(scalar) else {
            return true
        }
        current.appendToQuery(String(scalar).lowercased())
        state = current
        onChange()
        return true
    }
}
