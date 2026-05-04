import AppKit
import Foundation
import os

@MainActor
final class CapturePanelController: NSObject, NSTextFieldDelegate, NSWindowDelegate {
    private static let pageSize: Int = 20
    private let windowSize: Int = Applied.Capture.terminalDefaultWindowSize

    private let layout: CapturePanelLayout
    private let glance: GlanceController
    private let preview: PreviewLoader
    private let stats: StatsLoader
    private let entries: EntriesLoader
    private let history: CaptureHistoryCoordinator
    private let moveDispatcher: EntryMoveDispatcher
    private let dispatchCapture: @Sendable (_ rawText: String) async throws -> EntryListItem

    private struct RecentSave {
        let id: UUID
        let bin: Bin
    }

    private var page: CapturePageMode = .idle
    private var singlePreview: EntryListItem?
    private var sessionItems: [EntryListItem] = []
    private var previewLoading: Bool = false
    private var pendingGlance: Bool = false
    private var savedToastTask: Task<Void, Never>?
    private var recentSave: RecentSave?

    init(
        dispatchCapture: @escaping @Sendable (_ rawText: String) async throws -> EntryListItem,
        dispatchListRecent: @escaping @Sendable (_ limit: Int, _ scope: ListRecentEntriesQuery.Scope, _ before: ListRecentEntriesQuery.Cursor?) async throws -> [EntryListItem],
        dispatchMove: @escaping @Sendable (_ entryId: UUID, _ toBin: Bin) async throws -> Void,
        dispatchEntryStats: @escaping @Sendable (_ todayStartMillis: Int64, _ yesterdayStartMillis: Int64, _ staleCutoffMillis: Int64) async throws -> EntryStats
    ) {
        let layout = CapturePanelLayout.build()
        self.layout = layout
        self.glance = GlanceController(
            label: layout.glance,
            heightConstraint: layout.glanceHeightConstraint,
            bottomGapConstraint: layout.glanceBottomGapConstraint,
            lineHeight: layout.glanceLineHeight,
            bottomGap: Applied.Capture.glanceBottomGap,
            visibleSeconds: Applied.Capture.glanceVisibleSeconds
        )
        self.preview = PreviewLoader(dispatch: dispatchListRecent)
        self.stats = StatsLoader(dispatch: dispatchEntryStats)
        self.entries = EntriesLoader(dispatch: dispatchListRecent, pageSize: Self.pageSize)
        self.history = CaptureHistoryCoordinator(
            loader: EntriesLoader(dispatch: dispatchListRecent, pageSize: Self.pageSize)
        )
        self.moveDispatcher = EntryMoveDispatcher(dispatch: dispatchMove)
        self.dispatchCapture = dispatchCapture

        super.init()

        layout.field.delegate = self
        layout.panel.delegate = self
        layout.panel.onCancel = { [weak self] in self?.dismiss() }
        glance.onLayoutChange = { [weak self] in self?.updatePanelHeight() }
        refreshFooter()
    }

    func controlTextDidChange(_ obj: Notification) {
        // Cancel the baseline fetch so a capture write doesn't race with the read.
        preview.cancel()
        previewLoading = false
        history.exitRecall(currentField: layout.field.stringValue)
        let current: SlashSuggestionState = {
            if case .suggestions(let s) = page { return s }
            return .empty(windowSize: windowSize)
        }()
        applyPage(.suggestions(current.applying(text: layout.field.stringValue)))
        updatePanelHeight()
    }

    func windowDidResignKey(_ notification: Notification) {
        dismiss()
    }

    func show() {
        let interval = Signposts.signposter.beginInterval("panel-show")
        layout.field.stringValue = ""
        page = .idle
        history.reset()
        savedToastTask?.cancel()
        savedToastTask = nil
        recentSave = nil
        sessionItems = []
        stats.reset()
        preview.cancel()
        entries.cancel()
        if let cached = preview.cached {
            singlePreview = cached
            previewLoading = false
        } else {
            singlePreview = nil
            previewLoading = true
        }
        glance.hideImmediate()
        let now = Date()
        pendingGlance = glance.isFirstShowOfDay(at: now)
        refreshInputActive()
        render()
        layout.resetPanelHeight(glanceVisible: glance.isVisible)
        refreshFooter()
        layout.position()
        NSApp.activate(ignoringOtherApps: true)
        layout.panel.makeKeyAndOrderFront(nil)
        layout.panel.makeFirstResponder(layout.field)
        kickoffStatsLoad(now: now)
        if previewLoading { kickoffPreviewLoad() }
        Signposts.signposter.endInterval("panel-show", interval)
    }

    func dismiss() {
        page = .idle
        glance.hideImmediate()
        preview.cancel()
        stats.cancel()
        entries.cancel()
        history.cancel()
        savedToastTask?.cancel()
        savedToastTask = nil
        recentSave = nil
        sessionItems = []
        singlePreview = nil
        previewLoading = false
        layout.panel.orderOut(nil)
    }

    func toggle() {
        if layout.panel.isVisible {
            dismiss()
        } else {
            show()
        }
    }

    private func applyPage(_ next: CapturePageMode) {
        var normalized = next
        if case .suggestions(let s) = next, s.isEmpty {
            normalized = .idle
        }
        page = normalized
        refreshInputActive()
        render()
        refreshFooter()
    }

    private func refreshInputActive() {
        let active: Bool
        if case .entries = page { active = false } else { active = true }
        layout.prompt.setActive(active)
        layout.panel.setCursorActive(active)
    }

    private func refreshFooter() {
        layout.footer.setHints(CaptureFooterHints.hints(for: page, fieldText: layout.field.stringValue))
        if let bin = recentSave?.bin {
            layout.footer.setStat("✓ saved to \(bin.rawValue)", accent: true)
        } else {
            layout.footer.setStat(CaptureFooterHints.stat(from: stats.stats))
        }
    }

    private func render() {
        let view = CaptureResultsRenderer.view(
            for: page,
            fieldText: layout.field.stringValue,
            singlePreview: singlePreview,
            sessionItems: sessionItems,
            previewLoading: previewLoading,
            freshSavedId: recentSave?.id,
            now: Date()
        )
        CaptureResultsRenderer.apply(view, to: layout)
    }

    private func updatePanelHeight() {
        layout.updatePanelHeight(forText: layout.field.stringValue, glanceVisible: glance.isVisible)
    }

    private func commit(keepOpen: Bool = false) {
        if case .entries(let e) = page, let item = e.list.selected {
            toggleDone(item: item, in: e)
            return
        }
        let raw: String
        if case .suggestions(let s) = page, let pick = s.selected {
            raw = pick.token
        } else {
            raw = layout.field.stringValue
        }
        switch SlashCommand.parse(raw) {
        case .list(let scope):
            layout.field.stringValue = ""
            beginEntriesLoad(scope: scope)
        case .sound(let on):
            CaptureSoundPreference.setEnabled(on)
            layout.field.stringValue = ""
            if keepOpen {
                applyPage(.idle)
                updatePanelHeight()
            } else {
                dismiss()
            }
        case .capture(let text):
            guard !text.isEmpty else {
                if !keepOpen { dismiss() }
                return
            }
            CaptureSoundPreference.playIfEnabled()
            let dispatchCapture = self.dispatchCapture
            Task.detached { [weak self] in
                let interval = Signposts.signposter.beginInterval("dispatch-capture")
                defer { Signposts.signposter.endInterval("dispatch-capture", interval) }
                do {
                    let item = try await dispatchCapture(text)
                    await MainActor.run {
                        self?.adoptCapturedItem(item)
                    }
                } catch {
                    NSLog("OCS: capture failed: %@", String(describing: error))
                }
            }
            if keepOpen {
                layout.field.stringValue = ""
                history.reset()
                applyPage(.idle)
                updatePanelHeight()
            } else {
                dismiss()
            }
        }
    }

    private func stepHistoryBack() -> Bool {
        if let next = history.stepBack(
            currentField: layout.field.stringValue,
            onLoaded: { [weak self] state in self?.applyHistory(state) }
        ) {
            applyHistory(next)
        }
        return true
    }

    private func stepHistoryForward() -> Bool {
        if let next = history.stepForward() { applyHistory(next) }
        return true
    }

    private func applyHistory(_ next: CaptureHistoryState) {
        let text = next.displayText
        layout.field.stringValue = text
        if let editor = layout.field.currentEditor() {
            let len = (text as NSString).length
            editor.selectedRange = NSRange(location: len, length: 0)
        }
        render()
        refreshFooter()
        updatePanelHeight()
    }

    private func adoptCapturedItem(_ item: EntryListItem) {
        preview.adopt(item)
        previewLoading = false
        var stack = sessionItems
        stack.removeAll { $0.id == item.id }
        stack.insert(item, at: 0)
        if stack.count > windowSize { stack.removeLast(stack.count - windowSize) }
        sessionItems = stack
        guard layout.panel.isVisible else { return }
        savedToastTask?.cancel()
        recentSave = RecentSave(id: item.id, bin: item.bin)
        refreshFooter()
        render()
        updatePanelHeight()
        let visibleSeconds = Applied.Capture.savedToastSeconds
        savedToastTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(visibleSeconds))
            if Task.isCancelled { return }
            await MainActor.run {
                guard let self else { return }
                self.savedToastTask = nil
                self.recentSave = nil
                self.refreshFooter()
                self.render()
            }
        }
    }

    private func toggleDone(item: EntryListItem, in state: EntriesListPageState) {
        let target: Bin = item.bin == .done ? .inbox : .done
        moveAndUpdate(item: item, to: target, in: state)
    }

    private func handleBackspaceInEntries() -> Bool {
        guard case .entries(let e) = page, let item = e.list.selected else {
            return false
        }
        trashSelected(item: item, in: e)
        return true
    }

    private func moveAndUpdate(item: EntryListItem, to bin: Bin, in state: EntriesListPageState) {
        let next = EntryListItem(id: item.id, text: item.text, bin: bin, createdAt: item.createdAt)
        applyPage(.entries(state.replacingSelected(with: next)))
        if bin == .done || bin == .trash { dropFromPreview(id: item.id) }
        moveDispatcher.send(entryId: item.id, toBin: bin)
    }

    private func trashSelected(item: EntryListItem, in state: EntriesListPageState) {
        applyPage(.entries(state.removingSelected()))
        dropFromPreview(id: item.id)
        updatePanelHeight()
        moveDispatcher.send(entryId: item.id, toBin: .trash)
    }

    private func dropFromPreview(id: UUID) {
        sessionItems.removeAll { $0.id == id }
        preview.invalidateIfMatches(id)
        if singlePreview?.id == id { singlePreview = nil }
    }

    private func beginEntriesLoad(scope: ListRecentEntriesQuery.Scope) {
        let initial = EntriesListPageState.empty(windowSize: windowSize, scope: scope).startingLoad()
        applyPage(.entries(initial))
        updatePanelHeight()

        entries.loadFirst(
            scope: scope,
            onSpinnerReveal: { [weak self] in
                guard let self else { return }
                if case .entries(let e) = self.page, e.isLoadingMore, e.list.isEmpty, !e.loadingVisible {
                    self.applyPage(.entries(e.revealingLoad()))
                    self.updatePanelHeight()
                }
            },
            onResult: { [weak self] outcome in
                guard let self, case .entries(let e) = self.page else { return }
                switch outcome {
                case .loaded(let items):
                    self.applyPage(.entries(e.appending(items)))
                case .failed:
                    self.applyPage(.entries(e.failedLoad()))
                }
                self.updatePanelHeight()
            }
        )
    }

    private func loadMoreEntries(from state: EntriesListPageState) {
        guard let cursor = state.nextCursor else { return }
        applyPage(.entries(state.startingLoad()))
        entries.loadMore(scope: state.scope, before: cursor) { [weak self] outcome in
            guard let self, case .entries(let e) = self.page else { return }
            switch outcome {
            case .loaded(let items):
                self.applyPage(.entries(e.appending(items)))
            case .failed:
                self.applyPage(.entries(e.failedLoad()))
            }
            self.updatePanelHeight()
        }
    }

    private func kickoffStatsLoad(now: Date) {
        stats.load(now: now) { [weak self] result in
            guard let self else { return }
            self.refreshFooter()
            if case .entries = self.page {
                self.render()
                self.updatePanelHeight()
            }
            if self.pendingGlance, let text = GlanceController.text(for: result) {
                self.pendingGlance = false
                self.glance.markShown(at: Date())
                self.glance.show(text)
            }
        }
    }

    private func kickoffPreviewLoad() {
        preview.fetch { [weak self] item in
            guard let self else { return }
            self.singlePreview = item
            self.previewLoading = false
            if case .idle = self.page, self.sessionItems.isEmpty {
                self.render()
                self.updatePanelHeight()
            }
        }
    }

    func control(
        _ control: NSControl,
        textView: NSTextView,
        doCommandBy commandSelector: Selector
    ) -> Bool {
        guard let intent = CaptureKeyRouter.intent(for: commandSelector) else { return false }
        return perform(intent)
    }

    private func perform(_ intent: CaptureIntent) -> Bool {
        switch intent {
        case .dismiss:
            dismiss()
            return true
        case .commit(let keepOpen):
            commit(keepOpen: keepOpen)
            return true
        case .navigate(let direction):
            return navigate(direction)
        case .autocompleteSuggestion:
            return autocompleteSuggestion()
        case .deleteSelected:
            return handleBackspaceInEntries()
        case .consume:
            return true
        }
    }

    private func navigate(_ direction: CaptureNavDirection) -> Bool {
        switch page {
        case .idle:
            switch direction {
            case .up:
                return stepHistoryBack()
            case .down:
                if history.isActive {
                    return stepHistoryForward()
                }
                if layout.field.stringValue.isEmpty {
                    beginEntriesLoad(scope: .active)
                    return true
                }
                return false
            case .pageUp, .pageDown:
                return false
            }
        case .suggestions(let s):
            let next: SlashSuggestionState
            switch direction {
            case .down: next = s.cursorDown()
            case .up: next = s.cursorUp()
            case .pageDown: next = s.pageDown()
            case .pageUp: next = s.pageUp()
            }
            applyPage(.suggestions(next))
            return true
        case .entries(let e):
            if direction == .up && (e.list.isEmpty || e.list.cursor == 0) {
                entries.cancel()
                applyPage(.idle)
                updatePanelHeight()
                return true
            }
            guard !e.list.isEmpty else { return false }
            let next: EntriesListPageState
            switch direction {
            case .down: next = e.cursorDown()
            case .up: next = e.cursorUp()
            case .pageDown: next = e.pageDown()
            case .pageUp: next = e.pageUp()
            }
            applyPage(.entries(next))
            updatePanelHeight()
            if next.shouldLoadMore { loadMoreEntries(from: next) }
            return true
        }
    }

    private func autocompleteSuggestion() -> Bool {
        guard case .suggestions(let s) = page, let pick = s.selected else { return true }
        layout.field.stringValue = pick.token
        applyPage(.suggestions(s.applying(text: pick.token)))
        updatePanelHeight()
        return true
    }
}
