import AppKit

@MainActor
final class CapturePrompt: NSTextField {
    init() {
        super.init(frame: .zero)
        stringValue = ">"
        isEditable = false
        isSelectable = false
        isBordered = false
        isBezeled = false
        drawsBackground = false
        font = Applied.Capture.bodyFont
        textColor = Applied.Capture.promptColor
        translatesAutoresizingMaskIntoConstraints = false
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }
}
