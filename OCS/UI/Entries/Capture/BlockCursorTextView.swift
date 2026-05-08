import AppKit

@MainActor
final class BlockCursorTextView: NSTextView {
    var cursorTint: NSColor = Applied.Capture.cursorColor {
        didSet { cursorView.layer?.backgroundColor = cursorTint.cgColor }
    }

    private let cursorView = NSView()
    private let blinkHalfPeriod: CFTimeInterval = 0.53
    private let blinkKey = "blink"
    private var isCursorActive = true

    // TextKit 2 leaves layoutManager nil; force TextKit 1 so glyph rect APIs work.
    init() {
        let storage = NSTextStorage()
        let layout = NSLayoutManager()
        let container = NSTextContainer()
        storage.addLayoutManager(layout)
        layout.addTextContainer(container)
        super.init(frame: .zero, textContainer: container)
        insertionPointColor = .clear
        cursorView.wantsLayer = true
        cursorView.layer?.backgroundColor = cursorTint.cgColor
        cursorView.isHidden = true
        addSubview(cursorView)
        let nc = NotificationCenter.default
        nc.addObserver(
            self,
            selector: #selector(handleTextOrSelectionChange),
            name: NSText.didChangeNotification,
            object: self
        )
        nc.addObserver(
            self,
            selector: #selector(handleTextOrSelectionChange),
            name: NSTextView.didChangeSelectionNotification,
            object: self
        )
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    isolated deinit { NotificationCenter.default.removeObserver(self) }

    // Restart blink only on real edits, not on keystrokes the router consumed.
    @objc private func handleTextOrSelectionChange() {
        guard isCursorActive, !cursorView.isHidden else { return }
        repositionCursor()
        startBlink()
    }

    func setCursorActive(_ active: Bool) {
        guard active != isCursorActive else { return }
        isCursorActive = active
        if active { showAndBlink() } else { hideAndStop() }
    }

    override func becomeFirstResponder() -> Bool {
        let ok = super.becomeFirstResponder()
        if isCursorActive { showAndBlink() }
        return ok
    }

    override func resignFirstResponder() -> Bool {
        let ok = super.resignFirstResponder()
        hideAndStop()
        return ok
    }

    private func showAndBlink() {
        cursorView.isHidden = false
        repositionCursor()
        startBlink()
    }

    private func hideAndStop() {
        stopBlink()
        cursorView.isHidden = true
    }

    private func startBlink() {
        guard let layer = cursorView.layer else { return }
        layer.removeAnimation(forKey: blinkKey)
        layer.opacity = 1
        let blink = CAKeyframeAnimation(keyPath: "opacity")
        // Square-wave blink: duplicated keyTimes at 0.5 force a discrete jump.
        blink.values = [1.0, 1.0, 0.0, 0.0]
        blink.keyTimes = [0.0, 0.5, 0.5, 1.0]
        blink.duration = blinkHalfPeriod * 2
        blink.repeatCount = .infinity
        layer.add(blink, forKey: blinkKey)
    }

    private func stopBlink() {
        cursorView.layer?.removeAnimation(forKey: blinkKey)
        cursorView.layer?.opacity = 1
    }

    private func repositionCursor() {
        guard let layoutManager, let textContainer else { return }
        let glyphIndex = layoutManager.glyphIndexForCharacter(at: selectedRange().location)
        let rect = layoutManager.boundingRect(
            forGlyphRange: NSRange(location: glyphIndex, length: 0),
            in: textContainer
        )
        let width = font?.maximumAdvancement.width ?? max(rect.width, 8)
        let origin = textContainerOrigin
        cursorView.frame = NSRect(
            x: rect.origin.x + origin.x,
            y: rect.origin.y + origin.y,
            width: width,
            height: rect.height
        )
    }
}
