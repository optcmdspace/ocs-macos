import AppKit

@MainActor
enum CaptureRows {
    static func suggestion(_ spec: SlashCommand.Spec) -> TerminalRow.Spec {
        .init(primary: spec.token, secondary: spec.description)
    }

    static func tagSuggestion(_ s: TagSuggestion, trailingMinWidth: CGFloat) -> TerminalRow.Spec {
        .init(
            primary: "#\(s.name)",
            trailing: s.usageCount > 0 ? "\(s.usageCount)" : nil,
            trailingMinWidth: trailingMinWidth
        )
    }

    static func entry(_ item: EntryListItem, now: Date, trailingMinWidth: CGFloat) -> TerminalRow.Spec {
        .init(
            primary: item.text,
            tags: item.tags.isEmpty ? nil : item.tags,
            trailing: relativeStamp(from: item.createdAt, now: now),
            trailingMinWidth: trailingMinWidth,
            style: ageStyle(for: item.createdAt, now: now),
            strikethrough: item.bin == .done
        )
    }

    static func preview(_ item: EntryListItem, now: Date, trailingMinWidth: CGFloat, highlighted: Bool = false) -> TerminalRow.Spec {
        .init(
            primary: item.text,
            tags: item.tags.isEmpty ? nil : item.tags,
            trailing: relativeStamp(from: item.createdAt, now: now),
            trailingMinWidth: trailingMinWidth,
            style: highlighted ? .normal : .muted,
            strikethrough: item.bin == .done
        )
    }

    nonisolated static func ageStyle(for date: Date, now: Date) -> TerminalRow.Style {
        let age = now.timeIntervalSince(date)
        if age >= AgingThresholds.entryStaleAfterSeconds { return .faint }
        if age >= AgingThresholds.entryAgedAfterSeconds { return .aged }
        return .normal
    }

    nonisolated static func relativeStamp(from date: Date, now: Date) -> String {
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
