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
}
