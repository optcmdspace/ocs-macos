import AppKit

@MainActor
final class TerminalRowView: NSView {
    init(spec: TerminalRow.Spec) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        wantsLayer = true

        let marker = Self.makeMarker(visible: spec.style == .selected)
        let primary = Self.makePrimary(spec: spec)
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
            let trailing = Self.makeTrailing(text: trailingText)
            addSubview(trailing)
            constraints.append(contentsOf: Self.trailingConstraints(trailing: trailing, primary: primary, container: self, minWidth: spec.trailingMinWidth))
            rightLimit = trailing.leadingAnchor
            rightInset = Applied.Capture.outputItemGap
        }

        if let secondaryText = spec.secondary {
            let secondary = Self.makeSecondary(text: secondaryText)
            addSubview(secondary)
            // Primary hugs its content so the secondary takes the slack.
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

    private static func makeMarker(visible: Bool) -> NSTextField {
        let marker = NSTextField(labelWithString: visible ? Applied.Capture.terminalMarker : "")
        marker.font = Applied.Capture.outputFont
        marker.textColor = Applied.Capture.terminalMarkerColor
        marker.alignment = .left
        marker.translatesAutoresizingMaskIntoConstraints = false
        return marker
    }

    private static func makePrimary(spec: TerminalRow.Spec) -> NSTextField {
        let color = primaryColor(for: spec.style)
        let primary = NSTextField(labelWithString: spec.primary)
        primary.font = Applied.Capture.outputFont
        primary.textColor = color
        primary.lineBreakMode = .byTruncatingTail
        primary.maximumNumberOfLines = 1
        primary.translatesAutoresizingMaskIntoConstraints = false
        if spec.strikethrough {
            primary.attributedStringValue = NSAttributedString(
                string: spec.primary,
                attributes: [
                    .font: Applied.Capture.outputFont,
                    .foregroundColor: color,
                    .strikethroughStyle: NSUnderlineStyle.single.rawValue,
                    .strikethroughColor: color,
                ]
            )
        }
        return primary
    }

    private static func makeTrailing(text: String) -> NSTextField {
        let trailing = NSTextField(labelWithString: text)
        trailing.font = Applied.Capture.outputTimestampFont
        trailing.textColor = Applied.Capture.outputTimestampColor
        trailing.alignment = .right
        trailing.translatesAutoresizingMaskIntoConstraints = false
        trailing.setContentHuggingPriority(.required, for: .horizontal)
        trailing.setContentCompressionResistancePriority(.required, for: .horizontal)
        return trailing
    }

    private static func makeSecondary(text: String) -> NSTextField {
        let secondary = NSTextField(labelWithString: text)
        secondary.font = Applied.Capture.outputFont
        secondary.textColor = Applied.Capture.outputEmptyColor
        secondary.lineBreakMode = .byTruncatingTail
        secondary.maximumNumberOfLines = 1
        secondary.translatesAutoresizingMaskIntoConstraints = false
        secondary.setContentHuggingPriority(.defaultLow, for: .horizontal)
        secondary.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return secondary
    }

    private static func trailingConstraints(
        trailing: NSTextField,
        primary: NSTextField,
        container: NSView,
        minWidth: CGFloat
    ) -> [NSLayoutConstraint] {
        let inset = Applied.Capture.terminalMarkerWidth + Applied.Capture.terminalMarkerGap
        var c: [NSLayoutConstraint] = [
            trailing.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -inset),
            trailing.firstBaselineAnchor.constraint(equalTo: primary.firstBaselineAnchor),
        ]
        if minWidth > 0 {
            c.append(trailing.widthAnchor.constraint(greaterThanOrEqualToConstant: minWidth))
        }
        return c
    }

    private static func primaryColor(for style: TerminalRow.Style) -> NSColor {
        switch style {
        case .normal:   return Applied.Capture.outputTextColor
        case .selected: return Applied.Capture.terminalSelectedColor
        case .muted:    return Applied.Capture.outputEmptyColor
        case .aged:     return Applied.Capture.outputAgedColor
        case .faint:    return Applied.Capture.outputFaintColor
        }
    }
}
