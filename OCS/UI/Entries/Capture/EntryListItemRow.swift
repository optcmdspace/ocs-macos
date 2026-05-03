import AppKit

@MainActor
final class EntryListItemRow: NSStackView {
    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.setLocalizedDateFormatFromTemplate("MMM d, h:mm a")
        return f
    }()

    init(item: EntryListItem) {
        super.init(frame: .zero)
        orientation = .horizontal
        alignment = .firstBaseline
        spacing = Applied.Capture.outputItemGap
        distribution = .fill
        translatesAutoresizingMaskIntoConstraints = false

        let body = NSTextField(labelWithString: item.text)
        body.font = Applied.Capture.outputFont
        body.textColor = Applied.Capture.outputTextColor
        body.lineBreakMode = .byTruncatingTail
        body.maximumNumberOfLines = 1
        body.setContentHuggingPriority(.defaultLow, for: .horizontal)
        body.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let stamp = NSTextField(labelWithString: Self.formatter.string(from: item.createdAt))
        stamp.font = Applied.Capture.outputTimestampFont
        stamp.textColor = Applied.Capture.outputTimestampColor
        stamp.setContentHuggingPriority(.required, for: .horizontal)
        stamp.setContentCompressionResistancePriority(.required, for: .horizontal)

        addArrangedSubview(body)
        addArrangedSubview(stamp)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }
}
