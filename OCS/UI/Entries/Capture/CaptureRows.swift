import Foundation

nonisolated enum CaptureRows {
    static func suggestion(_ spec: SlashCommand.Spec) -> TerminalRow.Spec {
        .init(primary: spec.token, secondary: spec.description)
    }

    static func entry(_ item: EntryListItem) -> TerminalRow.Spec {
        .init(primary: item.text, trailing: stampFormatter.string(from: item.createdAt))
    }

    private static let stampFormatter: DateFormatter = {
        let f = DateFormatter()
        f.setLocalizedDateFormatFromTemplate("MMM d, h:mm a")
        return f
    }()
}
