import Foundation

nonisolated enum TerminalRow {
    nonisolated enum Style: Sendable, Equatable {
        case normal
        case selected
        case muted
        case soft
        case faint
        case command
        case commandSelected
    }

    nonisolated struct Spec: Sendable, Equatable {
        let primary: String
        let secondary: String?
        let tags: [String]?
        let trailing: String?
        let trailingMinWidth: CGFloat
        let style: Style
        let strikethrough: Bool
        // Case-insensitive substring of `primary` to chip; nil for no chip.
        let highlight: String?
        // A horizontal rule between row groups; when true the other fields are ignored.
        let isDivider: Bool

        nonisolated init(
            primary: String,
            secondary: String? = nil,
            tags: [String]? = nil,
            trailing: String? = nil,
            trailingMinWidth: CGFloat = 0,
            style: Style = .normal,
            strikethrough: Bool = false,
            highlight: String? = nil,
            isDivider: Bool = false
        ) {
            self.primary = primary
            self.secondary = secondary
            self.tags = tags
            self.trailing = trailing
            self.trailingMinWidth = trailingMinWidth
            self.style = style
            self.strikethrough = strikethrough
            self.highlight = highlight
            self.isDivider = isDivider
        }

        nonisolated static func message(_ text: String) -> Self {
            .init(primary: text, style: .muted)
        }

        nonisolated static let divider = Self(primary: "", isDivider: true)

        nonisolated func styled(_ newStyle: Style) -> Self {
            .init(
                primary: primary,
                secondary: secondary,
                tags: tags,
                trailing: trailing,
                trailingMinWidth: trailingMinWidth,
                style: newStyle,
                strikethrough: strikethrough,
                highlight: highlight,
                isDivider: isDivider
            )
        }

        // Selection variant per base style: command rows promote to .commandSelected so the renderer
        // can show full-amber + amber marker, while everything else collapses to the generic .selected.
        nonisolated func selectedStyle() -> Self {
            switch style {
            case .command: return styled(.commandSelected)
            default:       return styled(.selected)
            }
        }
    }
}
