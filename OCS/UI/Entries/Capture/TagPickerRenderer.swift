import AppKit

@MainActor
enum TagPickerRenderer {
    static func attributedString(for state: TagEditState) -> NSAttributedString {
        let result = NSMutableAttributedString()
        let names = state.allTagNames
        let draftActive = state.newTagDraft != nil
        for (index, name) in names.enumerated() {
            if result.length > 0 {
                result.append(NSAttributedString(string: "  ", attributes: [
                    .font: Applied.Capture.outputTagsFont,
                ]))
            }
            let applied = state.currentApplied.contains(name)
            let focused = !draftActive && index == state.cursor
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
        if let draft = state.newTagDraft {
            if result.length > 0 {
                result.append(NSAttributedString(string: "  ", attributes: [
                    .font: Applied.Capture.outputTagsFont,
                ]))
            }
            let prompt = "+\u{00A0}#\(draft)\u{00A0}"
            result.append(NSAttributedString(string: prompt, attributes: [
                .font: Applied.Capture.outputTagsFont,
                .foregroundColor: Applied.Capture.outputTextColor,
                .backgroundColor: Applied.Capture.outputEmptyColor.withAlphaComponent(0.18),
                .underlineStyle: NSUnderlineStyle.thick.rawValue,
                .underlineColor: Applied.Capture.outputTextColor,
            ]))
        }
        return result
    }
}
