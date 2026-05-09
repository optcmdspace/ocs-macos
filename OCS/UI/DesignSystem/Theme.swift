import AppKit

enum Theme {
    @MainActor
    enum Color {
        static let accent = NSColor(red: 0x17 / 255.0, green: 0xb8 / 255.0, blue: 0xb0 / 255.0, alpha: 1.0)
        static let accentMuted = NSColor(red: 0x17 / 255.0, green: 0xb8 / 255.0, blue: 0xb0 / 255.0, alpha: 0.5)

        static let foreground = NSColor(white: 1.0, alpha: 0.92)
        static let foregroundMuted = NSColor(white: 1.0, alpha: 0.45)
        static let foregroundSubtle = NSColor(white: 1.0, alpha: 0.25)
        static let foregroundFaint = NSColor(white: 1.0, alpha: 0.10)

        static let foregroundDimSolid = NSColor(white: 0.45, alpha: 1.0)

        static let backgroundScrim = NSColor(white: 0.0, alpha: 0.55)
    }

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
    }

    enum FontSize {
        static let xs: CGFloat = 11
        static let sm: CGFloat = 12
        static let md: CGFloat = 14
        static let lg: CGFloat = 16
        static let xl: CGFloat = 18
        static let xxl: CGFloat = 24
    }

    @MainActor
    enum Font {
        static let xs = NSFont.monospacedSystemFont(ofSize: FontSize.xs, weight: .regular)
        static let sm = NSFont.monospacedSystemFont(ofSize: FontSize.sm, weight: .regular)
        static let md = NSFont.monospacedSystemFont(ofSize: FontSize.md, weight: .regular)
        static let lg = NSFont.monospacedSystemFont(ofSize: FontSize.lg, weight: .regular)
        static let xl = NSFont.monospacedSystemFont(ofSize: FontSize.xl, weight: .regular)
        static let xxl = NSFont.monospacedSystemFont(ofSize: FontSize.xxl, weight: .regular)
    }

    enum Radius {
        static let none: CGFloat = 0
        static let sm: CGFloat = 4
        static let md: CGFloat = 6
        static let lg: CGFloat = 8
        static let xl: CGFloat = 12
    }

    enum Stroke {
        static let none: CGFloat = 0
        static let thin: CGFloat = 1
        static let medium: CGFloat = 2
        static let thick: CGFloat = 3
    }
}
