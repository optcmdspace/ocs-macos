import AppKit

@MainActor
final class CaptureFooter: NSTextField {
    init() {
        super.init(frame: .zero)
        stringValue = "Enter to submit"
        isEditable = false
        isSelectable = false
        isBordered = false
        isBezeled = false
        drawsBackground = false
        font = Applied.Capture.captionFont
        textColor = Applied.Capture.footerTextColor
        translatesAutoresizingMaskIntoConstraints = false
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }
}
