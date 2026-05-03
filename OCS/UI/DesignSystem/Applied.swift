import AppKit

enum Applied {
    @MainActor
    enum Capture {
        static let panelWidth: CGFloat = 640
        static let horizontalPadding = Theme.Spacing.xl
        static let verticalPadding = Theme.Spacing.lg
        static let promptGap = Theme.Spacing.md
        static let footerGap = Theme.Spacing.md
        static let footerBottomInset = Theme.Spacing.sm
        static let cornerRadius = Theme.Radius.md
        static let borderWidth = Theme.Stroke.thin

        static let outputTopGap = Theme.Spacing.md
        static let outputRowSpacing = Theme.Spacing.sm
        static let outputItemGap = Theme.Spacing.md

        static let cursorColor = Theme.Color.accent
        static let promptColor = Theme.Color.foregroundMuted
        static let textColor = Theme.Color.foreground
        static let placeholderColor = Theme.Color.foregroundSubtle
        static let footerTextColor = Theme.Color.foregroundSubtle
        static let tintColor = Theme.Color.backgroundScrim
        static let borderColor = Theme.Color.foregroundFaint

        static let outputTextColor = Theme.Color.foreground
        static let outputTimestampColor = Theme.Color.foregroundSubtle
        static let outputEmptyColor = Theme.Color.foregroundMuted

        static let terminalMarker = "❯"
        static let terminalMarkerColor = Theme.Color.accent
        static let terminalSelectedColor = Theme.Color.accent
        static let terminalMarkerGap = Theme.Spacing.sm
        static var terminalMarkerWidth: CGFloat {
            ceil((terminalMarker as NSString).size(withAttributes: [.font: outputFont]).width)
        }
        static let terminalDefaultWindowSize: Int = 8

        static let bodyFont = Theme.Font.xl
        static let captionFont = Theme.Font.sm
        static let outputFont = Theme.Font.md
        static let outputTimestampFont = Theme.Font.sm
    }
}
