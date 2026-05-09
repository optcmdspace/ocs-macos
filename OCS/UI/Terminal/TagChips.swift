import AppKit

@MainActor
enum TagChips {
    private static let pillPad = "\u{00A0}"
    private static let chipSpacing = " "

    static func attributedString(_ names: [String], selected: Bool) -> NSAttributedString {
        guard !names.isEmpty else { return NSAttributedString() }
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .right
        let result = NSMutableAttributedString()
        let baseAttrs: [NSAttributedString.Key: Any] = [
            .font: Applied.Capture.outputTagsFont,
            .paragraphStyle: paragraph,
        ]
        for (i, name) in names.enumerated() {
            if i > 0 {
                result.append(NSAttributedString(string: chipSpacing, attributes: baseAttrs))
            }
            let chip = "\(pillPad)#\(name)\(pillPad)"
            result.append(NSAttributedString(string: chip, attributes: [
                .font: Applied.Capture.outputTagsFont,
                .paragraphStyle: paragraph,
                .foregroundColor: TagPalette.foreground(for: name, selected: selected),
                .backgroundColor: TagPalette.background(for: name, selected: selected),
            ]))
        }
        return result
    }
}
