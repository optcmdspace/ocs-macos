import AppKit

@MainActor
final class CaptureFooter: NSView {
    private let hints: NSTextField
    private let stat: NSTextField

    init() {
        let hints = NSTextField(labelWithString: "")
        hints.font = Applied.Capture.captionFont
        hints.textColor = Applied.Capture.footerTextColor
        hints.lineBreakMode = .byTruncatingTail
        hints.translatesAutoresizingMaskIntoConstraints = false
        hints.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let stat = NSTextField(labelWithString: "")
        stat.font = Applied.Capture.statFont
        stat.textColor = Applied.Capture.statColor
        stat.alignment = .right
        stat.translatesAutoresizingMaskIntoConstraints = false
        stat.setContentHuggingPriority(.required, for: .horizontal)
        stat.setContentCompressionResistancePriority(.required, for: .horizontal)

        self.hints = hints
        self.stat = stat
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false

        addSubview(hints)
        addSubview(stat)

        NSLayoutConstraint.activate([
            hints.leadingAnchor.constraint(equalTo: leadingAnchor),
            hints.topAnchor.constraint(equalTo: topAnchor),
            hints.bottomAnchor.constraint(equalTo: bottomAnchor),
            hints.trailingAnchor.constraint(lessThanOrEqualTo: stat.leadingAnchor, constant: -Applied.Capture.outputItemGap),
            stat.trailingAnchor.constraint(equalTo: trailingAnchor),
            stat.firstBaselineAnchor.constraint(equalTo: hints.firstBaselineAnchor),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

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
        self.hints.attributedStringValue = result
    }

    func setStat(_ text: String) {
        stat.stringValue = text
    }
}
