import AppKit

@MainActor
enum CaptureFooterFormatter {
    static func attributedHints(_ hints: [(key: String, label: String)]) -> NSAttributedString {
        let labelAttrs: [NSAttributedString.Key: Any] = [
            .font: Applied.Capture.captionFont,
            .foregroundColor: Applied.Capture.footerTextColor,
        ]
        let keyAttrs: [NSAttributedString.Key: Any] = [
            .font: Applied.Capture.shortcutKeyFont,
            .foregroundColor: Applied.Capture.footerTextColor,
        ]
        let result = NSMutableAttributedString()
        for (i, hint) in hints.enumerated() {
            if i > 0 {
                result.append(NSAttributedString(string: Applied.Capture.shortcutSeparator, attributes: labelAttrs))
            }
            // Glyph-only keys (↑↓, ⏎) get the wider key font with kerning; tokens with letters (tab, esc, any char) blend in as plain text.
            let containsLetter = hint.key.contains(where: \.isLetter)
            let attrs = containsLetter ? labelAttrs : keyAttrs
            let keyString = NSMutableAttributedString(string: hint.key, attributes: attrs)
            if !containsLetter, keyString.length >= 2 {
                keyString.addAttribute(
                    .kern,
                    value: Applied.Capture.shortcutKeyKerning,
                    range: NSRange(location: 0, length: keyString.length - 1)
                )
            }
            result.append(keyString)
            result.append(NSAttributedString(string: " " + hint.label, attributes: labelAttrs))
        }
        return result
    }
}
