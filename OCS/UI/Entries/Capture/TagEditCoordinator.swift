import AppKit

@MainActor
final class TagEditCoordinator {
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
            let suggestions = (try? await dispatch("", 50)) ?? []
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
                    newTagDraft: nil
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
            if current.newTagDraft != nil {
                current.cancelDraft()
                state = current
                onChange()
            } else {
                exit(commit: false)
            }
            return true
        case CaptureKeyCodes.returnKey, CaptureKeyCodes.numpadEnter:
            if current.newTagDraft != nil {
                current.commitDraft()
                state = current
                onChange()
            } else {
                exit(commit: true)
            }
            return true
        case CaptureKeyCodes.leftArrow:
            guard current.newTagDraft == nil else { return true }
            current.cursorLeft()
            state = current
            onChange()
            return true
        case CaptureKeyCodes.rightArrow:
            guard current.newTagDraft == nil else { return true }
            current.cursorRight()
            state = current
            onChange()
            return true
        case CaptureKeyCodes.space:
            if current.newTagDraft != nil { return true }
            current.toggleFocused()
            state = current
            onChange()
            return true
        case CaptureKeyCodes.backspace:
            if current.newTagDraft != nil {
                current.backspaceDraft()
                state = current
                onChange()
            }
            return true
        default:
            break
        }
        let chars = event.charactersIgnoringModifiers ?? ""
        guard let scalar = chars.unicodeScalars.first,
              CharacterSet.alphanumerics.contains(scalar) else {
            return true
        }
        current.appendToDraft(String(scalar).lowercased())
        state = current
        onChange()
        return true
    }
}
