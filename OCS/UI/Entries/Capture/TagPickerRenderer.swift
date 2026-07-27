import AppKit

@MainActor
enum TagPickerRenderer {
    static func attributedString(for state: TagEditState, caretVisible: Bool = true) -> NSAttributedString {
        let result = NSMutableAttributedString()
        // Caret glyph is always present (only its alpha toggles) so the blink never reflows the chips.
        if !state.query.isEmpty {
            result.append(NSAttributedString(string: state.query, attributes: [
                .font: Applied.Capture.outputTagsFont,
                .foregroundColor: Applied.Capture.outputTextColor,
            ]))
            let caretColor = caretVisible
                ? Applied.Capture.tagQueryCaretColor
                : Applied.Capture.tagQueryCaretColor.withAlphaComponent(0)
            result.append(NSAttributedString(string: Applied.Capture.tagQueryCaret, attributes: [
                .font: Applied.Capture.outputTagsFont,
                .foregroundColor: caretColor,
            ]))
        }
        for (index, name) in state.matches.enumerated() {
            appendSeparator(to: result)
            let applied = state.currentApplied.contains(name)
            let focused = index == state.cursor
            let chip = "\u{00A0}#\(name)\u{00A0}"
            var attrs: [NSAttributedString.Key: Any] = [
                .font: Applied.Capture.outputTagsFont,
                .foregroundColor: TagPalette.foreground(for: name, selected: applied),
            ]
            if applied {
                attrs[.backgroundColor] = TagPalette.background(for: name, selected: true)
            }
            if focused {
                attrs[.underlineStyle] = NSUnderlineStyle.thick.rawValue
                attrs[.underlineColor] = Applied.Capture.outputTextColor
            }
            result.append(NSAttributedString(string: chip, attributes: attrs))
        }
        if state.showsNewSlot, let name = state.newTagName {
            appendSeparator(to: result)
            var attrs: [NSAttributedString.Key: Any] = [
                .font: Applied.Capture.outputTagsFont,
                .foregroundColor: Applied.Capture.outputTextColor,
                .backgroundColor: Applied.Capture.outputEmptyColor.withAlphaComponent(0.18),
            ]
            if state.isNewSlotFocused {
                attrs[.underlineStyle] = NSUnderlineStyle.thick.rawValue
                attrs[.underlineColor] = Applied.Capture.outputTextColor
            }
            let prompt = "+\u{00A0}#\(name)\u{00A0}"
            result.append(NSAttributedString(string: prompt, attributes: attrs))
        }
        return result
    }

    private static func appendSeparator(to result: NSMutableAttributedString) {
        guard result.length > 0 else { return }
        result.append(NSAttributedString(string: "  ", attributes: [
            .font: Applied.Capture.outputTagsFont,
        ]))
    }
}
