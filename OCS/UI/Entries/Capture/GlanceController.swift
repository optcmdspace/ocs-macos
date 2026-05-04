import AppKit
import Foundation

@MainActor
final class GlanceController {
    private static let lastShownDayKey = "OCSLastGlanceDay"

    private let label: NSTextField
    private let heightConstraint: NSLayoutConstraint
    private let bottomGapConstraint: NSLayoutConstraint
    private let lineHeight: CGFloat
    private let bottomGap: CGFloat
    private let visibleSeconds: TimeInterval
    private var timer: Timer?
    private(set) var isVisible: Bool = false

    var onLayoutChange: (() -> Void)?

    init(
        label: NSTextField,
        heightConstraint: NSLayoutConstraint,
        bottomGapConstraint: NSLayoutConstraint,
        lineHeight: CGFloat,
        bottomGap: CGFloat,
        visibleSeconds: TimeInterval
    ) {
        self.label = label
        self.heightConstraint = heightConstraint
        self.bottomGapConstraint = bottomGapConstraint
        self.lineHeight = lineHeight
        self.bottomGap = bottomGap
        self.visibleSeconds = visibleSeconds
    }

    func isFirstShowOfDay(at now: Date) -> Bool {
        let last = UserDefaults.standard.double(forKey: Self.lastShownDayKey)
        if last == 0 { return true }
        let lastDate = Date(timeIntervalSince1970: last)
        return !Calendar.current.isDate(lastDate, inSameDayAs: now)
    }

    func markShown(at now: Date) {
        UserDefaults.standard.set(now.timeIntervalSince1970, forKey: Self.lastShownDayKey)
    }

    func show(_ text: String) {
        cancelTimer()
        label.stringValue = text
        label.isHidden = false
        isVisible = true
        heightConstraint.constant = lineHeight
        bottomGapConstraint.constant = bottomGap
        onLayoutChange?()
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.18
            self.label.animator().alphaValue = 1.0
        }
        timer = Timer.scheduledTimer(withTimeInterval: visibleSeconds, repeats: false) { [weak self] _ in
            Task { @MainActor in self?.fadeOut() }
        }
    }

    func hideImmediate() {
        cancelTimer()
        label.alphaValue = 0
        label.isHidden = true
        isVisible = false
        heightConstraint.constant = 0
        bottomGapConstraint.constant = 0
        onLayoutChange?()
    }

    static func text(for stats: EntryStats) -> String? {
        var parts: [String] = []
        if stats.activeCount > 0 { parts.append("\(stats.activeCount) active") }
        if stats.yesterdayCount > 0 { parts.append("\(stats.yesterdayCount) yesterday") }
        guard !parts.isEmpty else { return nil }
        return parts.joined(separator: " · ")
    }

    private func fadeOut() {
        guard isVisible else { return }
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.25
            self.label.animator().alphaValue = 0.0
        }, completionHandler: { [weak self] in
            self?.hideImmediate()
        })
    }

    private func cancelTimer() {
        timer?.invalidate()
        timer = nil
    }
}
