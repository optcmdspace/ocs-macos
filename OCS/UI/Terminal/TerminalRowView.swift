import AppKit

@MainActor
final class TerminalRowView: NSView {
    init(spec: TerminalRow.Spec) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        wantsLayer = true

        let wrapsPrimary = spec.style == .selected

        let marker = Self.makeMarker(style: spec.style)
        let primary = Self.makePrimary(spec: spec, wraps: wrapsPrimary)
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

        var trailingField: NSTextField?
        var tagsField: NSTextField?

        var rightLimit: NSLayoutXAxisAnchor = trailingAnchor
        var rightInset: CGFloat = 0
        if let trailingText = spec.trailing {
            let trailing = Self.makeTrailing(text: trailingText, style: spec.style)
            addSubview(trailing)
            constraints.append(contentsOf: Self.trailingConstraints(trailing: trailing, primary: primary, container: self, minWidth: spec.trailingMinWidth))
            rightLimit = trailing.leadingAnchor
            rightInset = Applied.Capture.outputItemGap
            trailingField = trailing
        }

        if spec.secondary == nil, let names = spec.tags, !names.isEmpty {
            let tags = Self.makeTags(names: names, style: spec.style)
            addSubview(tags)
            tagsField = tags
            constraints.append(contentsOf: [
                tags.trailingAnchor.constraint(equalTo: rightLimit, constant: -rightInset),
                tags.firstBaselineAnchor.constraint(equalTo: primary.firstBaselineAnchor),
            ])
            rightLimit = tags.leadingAnchor
            rightInset = Applied.Capture.outputTagsLeadingGap
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

        if wrapsPrimary {
            primary.preferredMaxLayoutWidth = Self.wrapWidth(
                trailing: trailingField,
                tags: tagsField,
                trailingMinWidth: spec.trailingMinWidth
            )
        }

        NSLayoutConstraint.activate(constraints)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    private static func wrapWidth(trailing: NSTextField?, tags: NSTextField?, trailingMinWidth: CGFloat) -> CGFloat {
        let rowWidth = Applied.Capture.panelWidth - 2 * Applied.Capture.horizontalPadding
        let sideInset = Applied.Capture.terminalMarkerWidth + Applied.Capture.terminalMarkerGap
        var reserved = sideInset
        if let trailing {
            reserved += Applied.Capture.outputItemGap
                + max(ceil(trailing.intrinsicContentSize.width), trailingMinWidth)
                + sideInset
        }
        if let tags {
            reserved += Applied.Capture.outputTagsLeadingGap + ceil(tags.intrinsicContentSize.width)
        }
        return max(rowWidth - reserved, 1)
    }

    private static func makeMarker(style: TerminalRow.Style) -> NSTextField {
        let visible = style == .selected || style == .commandSelected
        let marker = NSTextField(labelWithString: visible ? Applied.Capture.terminalMarker : "")
        marker.font = Applied.Capture.outputFont
        marker.textColor = style == .commandSelected
            ? Applied.Capture.commandColor
            : Applied.Capture.terminalMarkerColor
        marker.alignment = .left
        marker.translatesAutoresizingMaskIntoConstraints = false
        return marker
    }

    private static func makePrimary(spec: TerminalRow.Spec, wraps: Bool) -> NSTextField {
        let color = spec.strikethrough ? Applied.Capture.outputStrikethroughColor : primaryColor(for: spec.style)
        let primary = NSTextField(labelWithString: spec.primary)
        primary.font = Applied.Capture.outputFont
        primary.textColor = color
        primary.lineBreakMode = wraps ? .byWordWrapping : .byTruncatingTail
        primary.maximumNumberOfLines = wraps ? 0 : 1
        primary.cell?.wraps = wraps
        primary.cell?.isScrollable = !wraps
        primary.translatesAutoresizingMaskIntoConstraints = false
        let needsAttributed = spec.strikethrough || (spec.highlight?.isEmpty == false)
        if needsAttributed {
            var attrs: [NSAttributedString.Key: Any] = [
                .font: Applied.Capture.outputFont,
                .foregroundColor: color,
            ]
            if spec.strikethrough {
                attrs[.strikethroughStyle] = NSUnderlineStyle.single.rawValue
                attrs[.strikethroughColor] = color
            }
            if wraps {
                let paragraph = NSMutableParagraphStyle()
                paragraph.lineBreakMode = .byWordWrapping
                attrs[.paragraphStyle] = paragraph
            }
            let attributed = NSMutableAttributedString(string: spec.primary, attributes: attrs)
            if let needle = spec.highlight, !needle.isEmpty {
                applyHighlight(to: attributed, needle: needle)
            }
            primary.attributedStringValue = attributed
        }
        return primary
    }

    private static func applyHighlight(to s: NSMutableAttributedString, needle: String) {
        let plain = s.string as NSString
        var searchRange = NSRange(location: 0, length: plain.length)
        while searchRange.length > 0 {
            let found = plain.range(of: needle, options: .caseInsensitive, range: searchRange)
            if found.location == NSNotFound { break }
            s.addAttribute(.backgroundColor, value: Applied.Capture.matchHighlightBackground, range: found)
            s.addAttribute(.foregroundColor, value: Applied.Capture.matchHighlightForeground, range: found)
            let nextStart = found.location + found.length
            searchRange = NSRange(location: nextStart, length: plain.length - nextStart)
        }
    }

    private static func makeTags(names: [String], style: TerminalRow.Style) -> NSTextField {
        let tags = NSTextField(labelWithAttributedString: TagChips.attributedString(names, selected: style == .selected))
        tags.alignment = .right
        tags.lineBreakMode = .byTruncatingHead
        tags.maximumNumberOfLines = 1
        tags.translatesAutoresizingMaskIntoConstraints = false
        tags.setContentHuggingPriority(.required, for: .horizontal)
        tags.setContentCompressionResistancePriority(.required, for: .horizontal)
        return tags
    }

    private static func makeTrailing(text: String, style: TerminalRow.Style) -> NSTextField {
        let trailing = NSTextField(labelWithString: text)
        trailing.font = Applied.Capture.outputTimestampFont
        trailing.textColor = style == .selected ? Applied.Capture.outputTimestampSelectedColor : Applied.Capture.outputTimestampColor
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
        case .normal:           return Applied.Capture.outputTextColor
        case .selected:         return Applied.Capture.terminalSelectedColor
        case .muted:            return Applied.Capture.outputEmptyColor
        case .soft:             return Applied.Capture.outputSoftColor
        case .faint:            return Applied.Capture.outputFaintColor
        case .command:          return Applied.Capture.commandColorMuted
        case .commandSelected:  return Applied.Capture.commandColor
        }
    }
}
