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

    func setCursorActive(_ active: Bool) {
        blockCursorEditor.setCursorActive(active)
    }

    func setCursorTint(_ color: NSColor) {
        blockCursorEditor.cursorTint = color
    }

    override func cancelOperation(_ sender: Any?) {
        onCancel?()
    }
}
