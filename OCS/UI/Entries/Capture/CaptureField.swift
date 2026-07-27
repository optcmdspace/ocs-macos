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
        setPlaceholder(Self.defaultPlaceholder)
        translatesAutoresizingMaskIntoConstraints = false
        setContentHuggingPriority(.defaultLow, for: .vertical)
        setContentCompressionResistancePriority(.defaultLow, for: .vertical)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    static let defaultPlaceholder = "a thought, a task, anything..."

    func setPlaceholder(_ text: String) {
        placeholderAttributedString = NSAttributedString(
            string: text,
            attributes: [
                .font: Applied.Capture.bodyFont,
                .foregroundColor: Applied.Capture.placeholderColor,
            ]
        )
    }

    // Whole-field tint for the scheduling input, where the entire text is one date directive: the due
    // color when it parses, plain text otherwise. (DueDateSyntax only highlights a trailing phrase.)
    func highlightAsDate(valid: Bool) {
        guard let editor = currentEditor() as? NSTextView, let storage = editor.textStorage else { return }
        let full = NSRange(location: 0, length: storage.length)
        guard full.length > 0 else { return }
        storage.beginEditing()
        storage.setAttributes(
            [
                .font: Applied.Capture.bodyFont,
                .foregroundColor: valid ? Applied.Capture.inputDueColor : Applied.Capture.textColor,
            ],
            range: full
        )
        storage.endEditing()
        (editor as? BlockCursorTextView)?.syncTintToCaretGlyph()
    }

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
        if let range = SlashCommand.leadingCommandRange(in: stringValue) {
            storage.addAttribute(.foregroundColor, value: Applied.Capture.commandColor, range: range)
        }
        for range in HashtagSyntax.tokenRanges(in: stringValue) {
            storage.addAttribute(.foregroundColor, value: Applied.Capture.inputTagColor, range: range)
        }
        for range in DueDateSyntax.tokenRanges(in: stringValue, now: Date()) {
            storage.addAttribute(.foregroundColor, value: Applied.Capture.inputDueColor, range: range)
        }
        storage.endEditing()
        (editor as? BlockCursorTextView)?.syncTintToCaretGlyph()
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
