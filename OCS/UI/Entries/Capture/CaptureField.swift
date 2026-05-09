import AppKit

@MainActor
final class CaptureField: NSTextField {
    init() {
        super.init(frame: .zero)
        isBezeled = false
        isBordered = false
        drawsBackground = false
        focusRingType = .none
        font = Applied.Capture.bodyFont
        textColor = Applied.Capture.textColor
        usesSingleLineMode = false
        cell?.wraps = true
        cell?.isScrollable = false
        lineBreakMode = .byWordWrapping
        placeholderAttributedString = NSAttributedString(
            string: "a thought, a task, anything...",
            attributes: [
                .font: Applied.Capture.bodyFont,
                .foregroundColor: Applied.Capture.placeholderColor,
            ]
        )
        translatesAutoresizingMaskIntoConstraints = false
        setContentHuggingPriority(.defaultLow, for: .vertical)
        setContentCompressionResistancePriority(.defaultLow, for: .vertical)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    func refreshTokenHighlight() {
        guard let editor = currentEditor() as? NSTextView,
              let storage = editor.textStorage else { return }
        let full = NSRange(location: 0, length: storage.length)
        guard full.length > 0 else { return }
        storage.beginEditing()
        storage.setAttributes(
            [
                .font: Applied.Capture.bodyFont,
                .foregroundColor: Applied.Capture.textColor,
            ],
            range: full
        )
        for range in HashtagSyntax.tokenRanges(in: stringValue) {
            storage.addAttribute(.foregroundColor, value: Applied.Capture.inputTagColor, range: range)
        }
        storage.endEditing()
    }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        let isReturn = event.keyCode == CaptureKeyCodes.returnKey || event.keyCode == CaptureKeyCodes.numpadEnter
        let onlyCommand = event.modifierFlags
            .intersection(.deviceIndependentFlagsMask) == .command
        if isReturn && onlyCommand {
            currentEditor()?.doCommand(by: #selector(NSResponder.insertNewline(_:)))
            return true
        }
        return super.performKeyEquivalent(with: event)
    }
}
