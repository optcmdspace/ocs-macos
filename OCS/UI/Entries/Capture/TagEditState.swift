import Foundation

@MainActor
struct TagEditState: Equatable {
    let entryId: UUID
    let availableTags: [TagSuggestion]
    var addedTags: [String]
    let originalApplied: Set<String>
    var currentApplied: Set<String>
    var cursor: Int
    var newTagDraft: String?

    var allTagNames: [String] {
        availableTags.map(\.name) + addedTags
    }

    var focusedTagName: String? {
        let names = allTagNames
        guard cursor >= 0, cursor < names.count else { return nil }
        return names[cursor]
    }

    var hasChanges: Bool {
        currentApplied != originalApplied
    }

    var diff: (toAdd: [String], toRemove: [String]) {
        let add = currentApplied.subtracting(originalApplied)
        let remove = originalApplied.subtracting(currentApplied)
        return (Array(add), Array(remove))
    }

    mutating func cursorLeft() {
        let count = allTagNames.count
        guard count > 0 else { return }
        cursor = (cursor - 1 + count) % count
    }

    mutating func cursorRight() {
        let count = allTagNames.count
        guard count > 0 else { return }
        cursor = (cursor + 1) % count
    }

    mutating func toggleFocused() {
        guard let name = focusedTagName else { return }
        if currentApplied.contains(name) {
            currentApplied.remove(name)
        } else {
            currentApplied.insert(name)
        }
    }

    mutating func appendToDraft(_ char: String) {
        let current = newTagDraft ?? ""
        let next = current + char
        if next.count <= 64 { newTagDraft = next }
    }

    mutating func backspaceDraft() {
        guard var draft = newTagDraft else { return }
        if draft.isEmpty {
            newTagDraft = nil
            return
        }
        draft.removeLast()
        newTagDraft = draft
    }

    mutating func commitDraft() {
        guard let draft = newTagDraft, let name = TagName(draft) else {
            newTagDraft = nil
            return
        }
        newTagDraft = nil
        let value = name.value
        if !addedTags.contains(value), !availableTags.contains(where: { $0.name == value }) {
            addedTags.append(value)
        }
        currentApplied.insert(value)
        if let idx = allTagNames.firstIndex(of: value) {
            cursor = idx
        }
    }

    mutating func cancelDraft() {
        newTagDraft = nil
    }
}
