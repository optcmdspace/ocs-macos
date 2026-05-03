import AppKit

nonisolated enum TerminalRow {
    nonisolated enum Style: Sendable, Equatable {
        case normal
        case selected
        case muted
    }

    nonisolated struct Spec: Sendable, Equatable {
        let primary: String
        let secondary: String?
        let trailing: String?
        let trailingMinWidth: CGFloat
        let style: Style
        let strikethrough: Bool

        nonisolated init(
            primary: String,
            secondary: String? = nil,
            trailing: String? = nil,
            trailingMinWidth: CGFloat = 0,
            style: Style = .normal,
            strikethrough: Bool = false
        ) {
            self.primary = primary
            self.secondary = secondary
            self.trailing = trailing
            self.trailingMinWidth = trailingMinWidth
            self.style = style
            self.strikethrough = strikethrough
        }

        nonisolated static func message(_ text: String) -> Self {
            .init(primary: text, style: .muted)
        }

        nonisolated func styled(_ newStyle: Style) -> Self {
            .init(
                primary: primary,
                secondary: secondary,
                trailing: trailing,
                trailingMinWidth: trailingMinWidth,
                style: newStyle,
                strikethrough: strikethrough
            )
        }
    }
}

@MainActor
final class TerminalRowView: NSView {
    init(spec: TerminalRow.Spec) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        wantsLayer = true

        let marker = NSTextField(labelWithString: spec.style == .selected ? Applied.Capture.terminalMarker : "")
        marker.font = Applied.Capture.outputFont
        marker.textColor = Applied.Capture.terminalMarkerColor
        marker.alignment = .left
        marker.translatesAutoresizingMaskIntoConstraints = false

        let primary = NSTextField(labelWithString: spec.primary)
        primary.font = Applied.Capture.outputFont
        primary.textColor = primaryColor(for: spec.style)
        primary.lineBreakMode = .byTruncatingTail
        primary.maximumNumberOfLines = 1
        primary.translatesAutoresizingMaskIntoConstraints = false
        if spec.strikethrough {
            primary.attributedStringValue = NSAttributedString(
                string: spec.primary,
                attributes: [
                    .font: Applied.Capture.outputFont,
                    .foregroundColor: primaryColor(for: spec.style),
                    .strikethroughStyle: NSUnderlineStyle.single.rawValue,
                    .strikethroughColor: primaryColor(for: spec.style),
                ]
            )
        }

        addSubview(marker)
        addSubview(primary)

        var constraints: [NSLayoutConstraint] = [
            marker.leadingAnchor.constraint(equalTo: leadingAnchor),
            marker.firstBaselineAnchor.constraint(equalTo: primary.firstBaselineAnchor),
            marker.widthAnchor.constraint(equalToConstant: Applied.Capture.terminalMarkerWidth),
            primary.leadingAnchor.constraint(equalTo: marker.trailingAnchor, constant: Applied.Capture.terminalMarkerGap),
            primary.topAnchor.constraint(equalTo: topAnchor),
            primary.bottomAnchor.constraint(equalTo: bottomAnchor),
        ]

        var rightLimit: NSLayoutXAxisAnchor = trailingAnchor
        var rightInset: CGFloat = 0

        if let trailingText = spec.trailing {
            let trailing = NSTextField(labelWithString: trailingText)
            trailing.font = Applied.Capture.outputTimestampFont
            trailing.textColor = Applied.Capture.outputTimestampColor
            trailing.alignment = .right
            trailing.translatesAutoresizingMaskIntoConstraints = false
            trailing.setContentHuggingPriority(.required, for: .horizontal)
            trailing.setContentCompressionResistancePriority(.required, for: .horizontal)
            addSubview(trailing)
            let trailingInset = Applied.Capture.terminalMarkerWidth + Applied.Capture.terminalMarkerGap
            constraints.append(contentsOf: [
                trailing.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -trailingInset),
                trailing.firstBaselineAnchor.constraint(equalTo: primary.firstBaselineAnchor),
            ])
            if spec.trailingMinWidth > 0 {
                constraints.append(trailing.widthAnchor.constraint(greaterThanOrEqualToConstant: spec.trailingMinWidth))
            }
            rightLimit = trailing.leadingAnchor
            rightInset = Applied.Capture.outputItemGap
        }

        if let secondaryText = spec.secondary {
            let secondary = NSTextField(labelWithString: secondaryText)
            secondary.font = Applied.Capture.outputFont
            secondary.textColor = Applied.Capture.outputEmptyColor
            secondary.lineBreakMode = .byTruncatingTail
            secondary.maximumNumberOfLines = 1
            secondary.translatesAutoresizingMaskIntoConstraints = false
            secondary.setContentHuggingPriority(.defaultLow, for: .horizontal)
            secondary.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            addSubview(secondary)

            primary.setContentHuggingPriority(.required, for: .horizontal)
            primary.setContentCompressionResistancePriority(.required, for: .horizontal)

            constraints.append(contentsOf: [
                secondary.leadingAnchor.constraint(equalTo: primary.trailingAnchor, constant: Applied.Capture.outputItemGap),
                secondary.firstBaselineAnchor.constraint(equalTo: primary.firstBaselineAnchor),
                secondary.trailingAnchor.constraint(lessThanOrEqualTo: rightLimit, constant: -rightInset),
            ])
        } else {
            primary.setContentHuggingPriority(.defaultLow, for: .horizontal)
            primary.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            constraints.append(primary.trailingAnchor.constraint(lessThanOrEqualTo: rightLimit, constant: -rightInset))
        }

        NSLayoutConstraint.activate(constraints)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    private func primaryColor(for style: TerminalRow.Style) -> NSColor {
        switch style {
        case .normal:   return Applied.Capture.outputTextColor
        case .selected: return Applied.Capture.terminalSelectedColor
        case .muted:    return Applied.Capture.outputEmptyColor
        }
    }
}
