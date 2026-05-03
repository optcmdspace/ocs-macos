import AppKit

@MainActor
final class CaptureFooter: NSTextField {
    init() {
        super.init(frame: .zero)
        isEditable = false
        isSelectable = false
        isBordered = false
        isBezeled = false
        drawsBackground = false
        font = Applied.Capture.captionFont
        textColor = Applied.Capture.footerTextColor
        translatesAutoresizingMaskIntoConstraints = false
        lineBreakMode = .byTruncatingTail
    }

    func setHints(_ hints: [(key: String, label: String)]) {
        let labelAttrs: [NSAttributedString.Key: Any] = [
            .font: Applied.Capture.captionFont,
            .foregroundColor: Applied.Capture.footerTextColor,
        ]
        let keyAttrs: [NSAttributedString.Key: Any] = [
            .font: Applied.Capture.shortcutKeyFont,
            .foregroundColor: Applied.Capture.footerTextColor,
        ]
        let result = NSMutableAttributedString()
        for (i, hint) in hints.enumerated() {
            if i > 0 {
                result.append(NSAttributedString(string: Applied.Capture.shortcutSeparator, attributes: labelAttrs))
            }
            let keyString = NSMutableAttributedString(string: hint.key, attributes: keyAttrs)
            if keyString.length >= 2 {
                keyString.addAttribute(
                    .kern,
                    value: Applied.Capture.shortcutKeyKerning,
                    range: NSRange(location: 0, length: keyString.length - 1)
                )
            }
            result.append(keyString)
            result.append(NSAttributedString(string: " " + hint.label, attributes: labelAttrs))
        }
        attributedStringValue = result
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }
}
