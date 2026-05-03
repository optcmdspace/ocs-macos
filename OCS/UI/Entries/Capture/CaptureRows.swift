import Foundation

nonisolated enum CaptureRows {
    static func suggestion(_ spec: SlashCommand.Spec) -> TerminalRow.Spec {
        .init(primary: spec.token, secondary: spec.description)
    }

    static func entry(_ item: EntryListItem, now: Date, trailingMinWidth: CGFloat) -> TerminalRow.Spec {
        .init(
            primary: item.text,
            trailing: relativeStamp(from: item.createdAt, now: now),
            trailingMinWidth: trailingMinWidth,
            strikethrough: item.bin == .done
        )
    }

    static func relativeStamp(from date: Date, now: Date) -> String {
        if now.timeIntervalSince(date) < 60 { return "now" }
        let comps = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: date,
            to: now
        )
        if let y = comps.year, y >= 1 { return "\(y)y" }
        if let mo = comps.month, mo >= 1 { return "\(mo)mo" }
        if let d = comps.day, d >= 1 { return "\(d)d" }
        if let h = comps.hour, h >= 1 { return "\(h)h" }
        if let m = comps.minute, m >= 1 { return "\(m)m" }
        return "now"
    }
}
