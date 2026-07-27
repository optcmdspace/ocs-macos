import Foundation

@MainActor
struct TagEditState: Equatable {
    let entryId: UUID
    let availableTags: [TagSuggestion]
    var addedTags: [String]
    let originalApplied: Set<String>
    var currentApplied: Set<String>
    var cursor: Int
    var query: String

    var universe: [String] {
        availableTags.map(\.name) + addedTags
    }

    var matches: [String] {
        guard !query.isEmpty else { return universe }
        return universe.filter { $0.hasPrefix(query) }
    }

    var newTagName: String? {
        guard !query.isEmpty else { return nil }
        return TagName(query)?.value
    }

    // No "+ new" when the query already names a visible tag.
    var showsNewSlot: Bool {
        guard let name = newTagName else { return false }
        return !matches.contains(name)
    }

    var navigableCount: Int {
        matches.count + (showsNewSlot ? 1 : 0)
    }

    var isNewSlotFocused: Bool {
        showsNewSlot && cursor == matches.count
    }

    var focusedTagName: String? {
        guard cursor >= 0, cursor < matches.count else { return nil }
        return matches[cursor]
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
        let count = navigableCount
        guard count > 0 else { return }
        cursor = (cursor - 1 + count) % count
    }

    mutating func cursorRight() {
        let count = navigableCount
        guard count > 0 else { return }
        cursor = (cursor + 1) % count
    }

    mutating func selectFocused() {
        if isNewSlotFocused {
            createFromQuery()
        } else if let name = focusedTagName {
            if currentApplied.contains(name) {
                currentApplied.remove(name)
            } else {
                currentApplied.insert(name)
            }
        }
    }

    mutating func appendToQuery(_ char: String) {
        let next = query + char
        guard next.count <= 64 else { return }
        query = next
        cursor = 0
    }

    mutating func backspaceQuery() {
        guard !query.isEmpty else { return }
        query.removeLast()
        cursor = 0
    }

    mutating func clearQuery() {
        query = ""
        cursor = 0
    }

    private mutating func createFromQuery() {
        guard let name = newTagName else { return }
        if !universe.contains(name) { addedTags.append(name) }
        currentApplied.insert(name)
        query = ""
        cursor = matches.firstIndex(of: name) ?? 0
    }
}
