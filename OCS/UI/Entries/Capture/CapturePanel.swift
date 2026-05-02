import AppKit

@MainActor
final class CapturePanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    var onCancel: (() -> Void)?

    private lazy var blockCursorEditor: BlockCursorTextView = {
        let tv = BlockCursorTextView()
        tv.isFieldEditor = true
        return tv
    }()

    convenience init(contentRect: NSRect) {
        self.init(
            contentRect: contentRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        level = .floating
        isFloatingPanel = true
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        hidesOnDeactivate = false
        isMovableByWindowBackground = false
        backgroundColor = .clear
        isOpaque = false
        hasShadow = true
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
    }

    override func fieldEditor(_ createFlag: Bool, for object: Any?) -> NSText? {
        if object is NSTextField {
            return blockCursorEditor
        }
        return super.fieldEditor(createFlag, for: object)
    }

    override func cancelOperation(_ sender: Any?) {
        onCancel?()
    }
}

@MainActor
final class BlockCursorTextView: NSTextView {
    override func drawInsertionPoint(in rect: NSRect, color: NSColor, turnedOn flag: Bool) {
        guard flag else { return }
        var blockRect = rect
        blockRect.size.width = font?.maximumAdvancement.width ?? rect.size.width
        Applied.Capture.cursorColor.setFill()
        blockRect.fill()
    }

    // Block cursor is wider than the caret rect AppKit invalidates, so widen the dirty area or the right edge clips on redraw.
    override func setNeedsDisplay(_ invalidRect: NSRect, avoidAdditionalLayout flag: Bool) {
        var rect = invalidRect
        rect.size.width += font?.maximumAdvancement.width ?? 0
        super.setNeedsDisplay(rect, avoidAdditionalLayout: flag)
    }
}
