import Foundation

nonisolated struct TerminalListState<Item: Sendable & Equatable>: Sendable, Equatable {
    let items: [Item]
    let cursor: Int
    let windowSize: Int

    init(windowSize: Int) {
        self.init(items: [], cursor: 0, windowSize: windowSize)
    }

    init(items: [Item], windowSize: Int) {
        self.init(items: items, cursor: 0, windowSize: windowSize)
    }

    init(items: [Item], cursor: Int, windowSize: Int) {
        precondition(windowSize > 0, "TerminalListState windowSize must be > 0")
        self.items = items
        self.windowSize = windowSize
        self.cursor = Self.clampCursor(cursor, count: items.count)
    }

    var isEmpty: Bool { items.isEmpty }
    var count: Int { items.count }

    var selected: Item? {
        items.indices.contains(cursor) ? items[cursor] : nil
    }

    // While overflowing, the cursor sits 3rd from the bottom of the visible items.
    var windowStart: Int {
        Self.computeStart(cursor: cursor, count: items.count, windowSize: windowSize)
    }

    // Indicators consume item slots, so total visible rows stays at windowSize once overflowing.
    var visibleRange: Range<Int> {
        let count = items.count
        if count <= windowSize { return 0..<count }
        let start = windowStart
        let topIndicator = start > 0 ? 1 : 0
        let remainingFromStart = count - start
        let maxItemSlots = windowSize - topIndicator
        let itemSlots: Int
        if remainingFromStart <= maxItemSlots {
            itemSlots = remainingFromStart
        } else {
            itemSlots = maxItemSlots - 1
        }
        return start..<(start + itemSlots)
    }

    var hiddenAbove: Int { windowStart }
    var hiddenBelow: Int { items.count - visibleRange.upperBound }

    func cursorDown() -> Self { moved(to: cursor + 1) }
    func cursorUp() -> Self { moved(to: cursor - 1) }
    func pageDown() -> Self { moved(to: cursor + max(1, windowSize - 1)) }
    func pageUp() -> Self { moved(to: cursor - max(1, windowSize - 1)) }
    func first() -> Self { moved(to: 0) }
    func last() -> Self { moved(to: items.count - 1) }

    func appending(_ more: [Item]) -> Self {
        Self(items: items + more, cursor: cursor, windowSize: windowSize)
    }

    func replacing(_ items: [Item]) -> Self {
        Self(items: items, windowSize: windowSize)
    }

    private func moved(to newCursor: Int) -> Self {
        Self(items: items, cursor: newCursor, windowSize: windowSize)
    }

    private static func clampCursor(_ c: Int, count: Int) -> Int {
        if count == 0 { return 0 }
        return max(0, min(c, count - 1))
    }

    private static func computeStart(cursor: Int, count: Int, windowSize: Int) -> Int {
        if count <= windowSize { return 0 }
        if cursor <= windowSize - 4 { return 0 }
        if cursor >= count - 3 { return count - (windowSize - 1) }
        return cursor - (windowSize - 5)
    }
}

extension TerminalListState {
    func renderedRows(_ rowFor: (Item) -> TerminalRow.Spec) -> [TerminalRow.Spec] {
        var specs: [TerminalRow.Spec] = []
        if hiddenAbove > 0 {
            specs.append(.message("↑ \(hiddenAbove) more"))
        }
        for i in visibleRange {
            let spec = rowFor(items[i])
            specs.append(i == cursor ? spec.styled(.selected) : spec)
        }
        if hiddenBelow > 0 {
            specs.append(.message("↓ \(hiddenBelow) more"))
        }
        return specs
    }
}
