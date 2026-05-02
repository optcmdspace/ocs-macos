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

        static let cursorColor = Theme.Color.accent
        static let promptColor = Theme.Color.foregroundMuted
        static let textColor = Theme.Color.foreground
        static let placeholderColor = Theme.Color.foregroundSubtle
        static let footerTextColor = Theme.Color.foregroundSubtle
        static let tintColor = Theme.Color.backgroundScrim
        static let borderColor = Theme.Color.foregroundFaint

        static let bodyFont = Theme.Font.xl
        static let captionFont = Theme.Font.sm
    }
}
