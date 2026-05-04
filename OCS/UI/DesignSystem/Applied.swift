import AppKit

enum Applied {
    @MainActor
    enum Capture {
        static let panelWidth: CGFloat = 640
        static let horizontalPadding = Theme.Spacing.xl
        static let verticalPadding = Theme.Spacing.lg
        static let promptGap = Theme.Spacing.sm
        static let footerGap = Theme.Spacing.md
        static let footerBottomInset = Theme.Spacing.sm
        static let cornerRadius = Theme.Radius.md
        static let borderWidth = Theme.Stroke.thin

        static let outputTopGap = Theme.Spacing.md
        static let outputRowSpacing = Theme.Spacing.sm
        static let outputItemGap = Theme.Spacing.md
        static let dividerHeight = Theme.Stroke.thin
        static let dividerColor = Theme.Color.foregroundFaint

        static let cursorColor = Theme.Color.accent
        static let cursorColorMuted = Theme.Color.foregroundMuted
        static let promptColor = Theme.Color.accent
        static let promptColorMuted = Theme.Color.foregroundMuted
        static let textColor = Theme.Color.foreground
        static let placeholderColor = Theme.Color.foregroundSubtle
        static let footerTextColor = Theme.Color.foregroundSubtle
        static let tintColor = Theme.Color.backgroundScrim
        static let borderColor = Theme.Color.foregroundFaint

        static let outputTextColor = Theme.Color.foreground
        static let outputAgedColor = Theme.Color.foregroundMuted
        static let outputFaintColor = Theme.Color.foregroundSubtle
        static let outputTimestampColor = Theme.Color.foregroundSubtle
        static let outputEmptyColor = Theme.Color.foregroundMuted

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
        static var outputTimestampMinWidth: CGFloat {
            ceil(("00mo" as NSString).size(withAttributes: [.font: outputTimestampFont]).width)
        }
    }
}
