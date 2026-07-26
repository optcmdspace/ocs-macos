import AppKit

enum Applied {
    @MainActor
    enum Capture {
        static let panelWidth: CGFloat = 640
        static let horizontalPadding = Theme.Spacing.xxl
        static let verticalPadding = Theme.Spacing.xl
        static let promptGap = Theme.Spacing.sm
        static let footerGap = Theme.Spacing.md
        static let footerBottomInset = Theme.Spacing.xl
        static let cornerRadius = Theme.Radius.xl
        static let borderWidth = Theme.Stroke.thin

        static let outputTopGap = Theme.Spacing.md
        static let outputRowSpacing = Theme.Spacing.sm
        static let outputItemGap = Theme.Spacing.md
        static let outputTagsLeadingGap = Theme.Spacing.lg
        static let dividerHeight = Theme.Stroke.thin
        static let dividerColor = Theme.Color.foregroundFaint

        static let cursorColor = Theme.Color.accent
        static let promptColor = Theme.Color.accent
        static let promptColorMuted = Theme.Color.foregroundMuted
        static let textColor = Theme.Color.foreground
        static let inputTagColor = Theme.Color.accent
        static let inputDueColor = Theme.Color.date
        static let commandColor = Theme.Color.command
        static let commandColorMuted = Theme.Color.commandMuted
        static let matchHighlightForeground = Theme.Color.accent
        static let matchHighlightBackground = Theme.Color.accentDim
        static let placeholderColor = Theme.Color.foregroundSubtle
        static let footerTextColor = Theme.Color.foregroundSubtle
        static let tintColor = Theme.Color.backgroundScrim
        static let borderColor = Theme.Color.foregroundFaint

        static let outputTextColor = Theme.Color.foreground
        static let outputSoftColor = Theme.Color.foregroundSoft
        static let outputFaintColor = Theme.Color.foregroundSubtle
        static let outputTimestampColor = Theme.Color.foregroundSubtle
        static let outputTimestampSelectedColor = Theme.Color.foregroundMuted
        static let outputEmptyColor = Theme.Color.foregroundMuted
        static let outputStrikethroughColor = Theme.Color.foregroundDimSolid

        static let glanceColor = Theme.Color.foregroundMuted
        static let glanceFont = Theme.Font.sm
        static let glanceBottomGap = Theme.Spacing.sm
        static let glanceVisibleSeconds: TimeInterval = 1

        static let savedToastSeconds: TimeInterval = 1

        static let statColor = Theme.Color.foregroundSubtle
        static let statAccentColor = Theme.Color.accent
        static let statFont = Theme.Font.sm

        static let loadingDotColor = Theme.Color.foreground
        static let loadingDotSpacing: CGFloat = 4
        static let loadingDotPeriod: CFTimeInterval = 1.0
        static let loadingDotMinAlpha: CGFloat = 0.25

        static let shortcutSeparator = " · "
        static let shortcutKeyKerning: CGFloat = 2
        static let terminalMarker = ">"
        static let terminalMarkerColor = Theme.Color.accent
        static let terminalSelectedColor = Theme.Color.accent
        static let terminalMarkerGap = Theme.Spacing.sm
        static var terminalMarkerWidth: CGFloat {
            ceil((terminalMarker as NSString).size(withAttributes: [.font: outputFont]).width)
        }
        static let terminalDefaultWindowSize: Int = 8

        static let bodyFont = Theme.Font.md
        static let captionFont = Theme.Font.sm
        static let shortcutKeyFont = Theme.Font.md
        static let outputFont = Theme.Font.md
        static let outputTimestampFont = Theme.Font.sm
        static let outputTagsFont = Theme.Font.sm
        static var outputTimestampMinWidth: CGFloat {
            ceil(("00mo" as NSString).size(withAttributes: [.font: outputTimestampFont]).width)
        }
    }
}
