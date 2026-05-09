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
        self.hints.attributedStringValue = CaptureFooterFormatter.attributedHints(hints)
    }

    func setStat(_ text: String, accent: Bool = false) {
        stat.stringValue = text
        stat.textColor = accent ? Applied.Capture.statAccentColor : Applied.Capture.statColor
    }
}
