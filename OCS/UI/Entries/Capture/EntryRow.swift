import Foundation

// A row in the entries list: an entry, or a disclosure row (the collapsed summary) the cursor can land
// on and expand. Generic so the key means "expand the selected row", not "overdue".
nonisolated enum EntryRow: Sendable, Equatable {
    case entry(EntryListItem)
    case collapsedOverdue(count: Int)

    var entry: EntryListItem? {
        if case .entry(let item) = self { return item }
        return nil
    }

    var isExpandable: Bool {
        if case .collapsedOverdue = self { return true }
        return false
    }
}
