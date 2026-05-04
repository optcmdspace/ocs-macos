import AppKit

@MainActor
final class BlockCursorTextView: NSTextView {
    var cursorTint: NSColor = Applied.Capture.cursorColor {
        didSet { setNeedsDisplay(bounds) }
    }

    override func drawInsertionPoint(in rect: NSRect, color: NSColor, turnedOn flag: Bool) {
        guard flag else { return }
        var blockRect = rect
        blockRect.size.width = font?.maximumAdvancement.width ?? rect.size.width
        cursorTint.setFill()
        blockRect.fill()
    }

    // Block cursor is wider than the caret rect AppKit invalidates, so widen the dirty area or the right edge clips on redraw.
    override func setNeedsDisplay(_ invalidRect: NSRect, avoidAdditionalLayout flag: Bool) {
        var rect = invalidRect
        rect.size.width += font?.maximumAdvancement.width ?? 0
        super.setNeedsDisplay(rect, avoidAdditionalLayout: flag)
    }
}
