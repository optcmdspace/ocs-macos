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

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        let isReturn = event.keyCode == 36 || event.keyCode == 76
        let onlyCommand = event.modifierFlags
            .intersection(.deviceIndependentFlagsMask) == .command
        if isReturn && onlyCommand {
            currentEditor()?.doCommand(by: #selector(NSResponder.insertNewline(_:)))
            return true
        }
        return super.performKeyEquivalent(with: event)
    }
}
