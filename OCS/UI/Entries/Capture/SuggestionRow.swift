import AppKit

@MainActor
final class SuggestionRow: NSView {
    init(spec: SlashCommand.Spec, selected: Bool) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        wantsLayer = true
        layer?.cornerRadius = Applied.Capture.suggestionCornerRadius
        layer?.backgroundColor = selected
            ? Applied.Capture.suggestionSelectedBackground.cgColor
            : NSColor.clear.cgColor

        let token = NSTextField(labelWithString: spec.token)
        token.font = Applied.Capture.outputFont
        token.textColor = Applied.Capture.outputTextColor
        token.translatesAutoresizingMaskIntoConstraints = false
        token.setContentHuggingPriority(.required, for: .horizontal)
        token.setContentCompressionResistancePriority(.required, for: .horizontal)

        let desc = NSTextField(labelWithString: spec.description)
        desc.font = Applied.Capture.outputFont
        desc.textColor = Applied.Capture.suggestionDescriptionColor
        desc.lineBreakMode = .byTruncatingTail
        desc.maximumNumberOfLines = 1
        desc.translatesAutoresizingMaskIntoConstraints = false
        desc.setContentHuggingPriority(.defaultLow, for: .horizontal)
        desc.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        addSubview(token)
        addSubview(desc)

        let hPad = Applied.Capture.suggestionRowHorizontalPadding
        let vPad = Applied.Capture.suggestionRowVerticalPadding
        let gap = Applied.Capture.suggestionTokenGap

        NSLayoutConstraint.activate([
            token.leadingAnchor.constraint(equalTo: leadingAnchor, constant: hPad),
            token.topAnchor.constraint(equalTo: topAnchor, constant: vPad),
            token.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -vPad),
            desc.leadingAnchor.constraint(equalTo: token.trailingAnchor, constant: gap),
            desc.firstBaselineAnchor.constraint(equalTo: token.firstBaselineAnchor),
            desc.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -hPad),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }
}
