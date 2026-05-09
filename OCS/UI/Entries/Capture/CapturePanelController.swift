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
    private var tagAutocomplete: TagAutocompleteCoordinator!
    private var tagEditCoordinator: TagEditCoordinator!

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
    private var rejectionToastTask: Task<Void, Never>?
    private var recentRejection: String?
    private var keyMonitor: Any?
    private var liveFind: LiveFindCoordinator!

    init(
        dispatchCapture: @escaping @Sendable (_ rawText: String) async throws -> EntryListItem,
        dispatchEntries: @escaping @Sendable (_ limit: Int, _ scope: ListRecentEntriesQuery.Scope, _ filter: EntriesFilter, _ before: ListRecentEntriesQuery.Cursor?) async throws -> [EntryListItem],
        dispatchMove: @escaping @Sendable (_ entryId: UUID, _ toBin: Bin) async throws -> Void,
        dispatchEntryStats: @escaping @Sendable (_ todayStartMillis: Int64, _ yesterdayStartMillis: Int64, _ staleCutoffMillis: Int64) async throws -> EntryStats,
        dispatchTagSuggestions: @escaping DispatchTagSuggestions,
        dispatchSetEntryTags: @escaping DispatchSetEntryTags
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
        let unfiltered: @Sendable (Int, ListRecentEntriesQuery.Scope, ListRecentEntriesQuery.Cursor?) async throws -> [EntryListItem] = { limit, scope, before in
            try await dispatchEntries(limit, scope, .none, before)
        }
        self.preview = PreviewLoader(dispatch: unfiltered)
        self.stats = StatsLoader(dispatch: dispatchEntryStats)
        self.entries = EntriesLoader(dispatch: dispatchEntries, pageSize: Self.pageSize)
        self.history = CaptureHistoryCoordinator(
            loader: EntriesLoader(dispatch: dispatchEntries, pageSize: Self.pageSize)
        )
        self.moveDispatcher = EntryMoveDispatcher(dispatch: dispatchMove)
        self.dispatchCapture = dispatchCapture

        super.init()

        self.tagAutocomplete = TagAutocompleteCoordinator(
            dispatch: dispatchTagSuggestions,
            windowSize: windowSize,
            getPage: { [weak self] in self?.page ?? .idle },
            setPage: { [weak self] in self?.applyPage($0) },
            onHeightChange: { [weak self] in self?.updatePanelHeight() }
        )

        self.liveFind = LiveFindCoordinator(
            dispatch: dispatchEntries,
            pageSize: Self.pageSize,
            windowSize: windowSize,
            getPage: { [weak self] in self?.page ?? .idle },
            setPage: { [weak self] in self?.applyPage($0) },
            onHeightChange: { [weak self] in self?.updatePanelHeight() }
        )

        self.tagEditCoordinator = TagEditCoordinator(
            dispatchSuggestions: dispatchTagSuggestions,
            dispatchSetTags: dispatchSetEntryTags,
            onChange: { [weak self] in
                self?.refreshFooter()
                self?.updatePanelHeight()
            },
            onCommit: { [weak self] entryId, applied in
                self?.applyTagsLocally(entryId: entryId, applied: applied)
            }
        )

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
        layout.field.refreshTokenHighlight()
        let raw = layout.field.stringValue
        let cursor = layout.field.currentEditor()?.selectedRange.location ?? (raw as NSString).length
        if !tagAutocomplete.handleFieldChange(raw: raw, cursor: cursor) {
            if !liveFind.handleFieldChange(raw: raw) {
                liveFind.cancel()
                let current: SlashSuggestionState = {
                    if case .suggestions(let s) = page { return s }
                    return .empty(windowSize: windowSize)
                }()
                applyPage(.suggestions(current.applying(text: raw)))
            }
        }
        updatePanelHeight()
    }

    func windowDidResignKey(_ notification: Notification) {
        dismiss()
    }

    func show() {
        let interval = Signposts.signposter.beginInterval("panel-show")
        let draft = CaptureDraftStore.text
        layout.field.stringValue = draft
        let suggestion = SlashSuggestionState.empty(windowSize: windowSize).applying(text: draft)
        page = suggestion.isEmpty ? .idle : .suggestions(suggestion)
        history.reset()
        savedToastTask?.cancel()
        savedToastTask = nil
        recentSave = nil
        rejectionToastTask?.cancel()
        rejectionToastTask = nil
        recentRejection = nil
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
        tagAutocomplete.cancel()
        glance.hideImmediate()
        let now = Date()
        pendingGlance = glance.isFirstShowOfDay(at: now)
        refreshInputActive()
        render()
        layout.updatePanelHeight(forText: draft, glanceVisible: glance.isVisible)
        refreshFooter()
        layout.position()
        NSApp.activate(ignoringOtherApps: true)
        layout.panel.makeKeyAndOrderFront(nil)
        layout.panel.makeFirstResponder(layout.field)
        installKeyMonitor()
        if !draft.isEmpty, let editor = layout.field.currentEditor() {
            let len = (draft as NSString).length
            editor.selectedRange = NSRange(location: len, length: 0)
        }
        layout.field.refreshTokenHighlight()
        kickoffStatsLoad(now: now)
        if previewLoading { kickoffPreviewLoad() }
        Signposts.signposter.endInterval("panel-show", interval)
    }

    func dismiss() {
        CaptureDraftStore.save(layout.field.stringValue)
        page = .idle
        glance.hideImmediate()
        preview.cancel()
        stats.cancel()
        entries.cancel()
        liveFind.cancel()
        tagAutocomplete.cancel()
        history.cancel()
        savedToastTask?.cancel()
        savedToastTask = nil
        recentSave = nil
        rejectionToastTask?.cancel()
        rejectionToastTask = nil
        recentRejection = nil
        sessionItems = []
        singlePreview = nil
        previewLoading = false
        if tagEditCoordinator.isActive { tagEditCoordinator.exit(commit: false) }
        layout.setTagPicker(nil)
        uninstallKeyMonitor()
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
        // .entries (arrow-down list) takes the cursor over for navigation; .findResults keeps
        // the field active so the user can keep refining the live query.
        if case .entries = page { active = false } else { active = true }
        layout.prompt.setActive(active)
        layout.panel.setCursorActive(active)
        refreshCursorTint()
    }

    private func refreshCursorTint() {
        let tint: NSColor = SlashCommand.leadingCommandRange(in: layout.field.stringValue) != nil
            ? Applied.Capture.commandColor
            : Applied.Capture.cursorColor
        layout.panel.setCursorTint(tint)
    }

    private func refreshFooter() {
        if let state = tagEditCoordinator?.state {
            layout.footer.setHints(CaptureFooterHints.hints(forTagEdit: state))
            let count = state.currentApplied.count
            layout.footer.setStat(count == 0 ? "no tags" : "\(count) tag\(count == 1 ? "" : "s")")
            layout.setTagPicker(TagPickerRenderer.attributedString(for: state))
            return
        }
        layout.setTagPicker(nil)
        let statText: String
        let statAccent: Bool
        if let bin = recentSave?.bin {
            statText = "✓ saved to \(bin.rawValue)"
            statAccent = true
        } else if let message = recentRejection {
            statText = message
            statAccent = true
        } else {
            statText = CaptureFooterHints.stat(from: stats.stats)
            statAccent = false
        }
        layout.footer.setStat(statText, accent: statAccent)
        let hints: [CaptureFooterHints.Hint] = statText.count > 20
            ? []
            : CaptureFooterHints.hints(for: page, fieldText: layout.field.stringValue)
        layout.footer.setHints(hints)
    }

    private func flashRejection(_ message: String) {
        rejectionToastTask?.cancel()
        recentRejection = message
        refreshFooter()
        let visibleSeconds = Applied.Capture.savedToastSeconds
        rejectionToastTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(visibleSeconds))
            if Task.isCancelled { return }
            await MainActor.run {
                guard let self else { return }
                self.rejectionToastTask = nil
                self.recentRejection = nil
                self.refreshFooter()
            }
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
        // Inside /find, an Enter while a tag suggestion is highlighted accepts the suggestion;
        // acceptTagSuggestion re-triggers the live find so the search runs against the resolved tag.
        if case .tagSuggestions(let t) = page,
           let pick = t.selected,
           LiveFindCoordinator.isFindContext(layout.field.stringValue)
        {
            _ = acceptTagSuggestion(pick, in: t)
            return
        }
        if case .entries(let e) = page, let item = e.list.selected {
            toggleDone(item: item, in: e)
            return
        }
        if case .findResults(let e) = page, let item = e.list.selected {
            toggleFindDone(item: item, in: e)
            return
        }
        let raw: String
        if case .suggestions(let s) = page, let pick = s.selected {
            // Intermediate picks (e.g. "/set") don't parse to a command; treat Enter as Tab so
            // the user descends into the next suggestion level instead of saving the token literally.
            if case .capture = SlashCommand.parse(pick.token) {
                applyAutocomplete(token: pick.token)
                return
            }
            raw = pick.token
        } else {
            raw = layout.field.stringValue
        }
        switch SlashCommand.parse(raw) {
        case .find:
            // Either the user picked /find from the catalog or hit Enter on a bare /find. Move into
            // live-find mode with whatever's in the field; the user can keep typing to refine.
            let prefilled = raw.lowercased() == "/find" ? "/find " : raw
            layout.field.stringValue = prefilled
            if let editor = layout.field.currentEditor() {
                let len = (prefilled as NSString).length
                editor.selectedRange = NSRange(location: len, length: 0)
            }
            layout.field.refreshTokenHighlight()
            liveFind.kickoff(raw: prefilled)
        case .setSound(let on):
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
            let parsed = HashtagParser.parse(text)
            if parsed.body.isEmpty {
                flashRejection("needs body text — tags alone aren't a capture")
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
            layout.field.stringValue = ""
            if keepOpen {
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
        layout.field.refreshTokenHighlight()
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
        let next = EntryListItem(id: item.id, text: item.text, bin: bin, createdAt: item.createdAt, tags: item.tags)
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

    private func beginEntriesLoad(scope: ListRecentEntriesQuery.Scope, filter: EntriesFilter = .none) {
        let initial = EntriesListPageState.empty(windowSize: windowSize, scope: scope, filter: filter).startingLoad()
        applyPage(.entries(initial))
        updatePanelHeight()

        entries.loadFirst(
            scope: scope,
            filter: filter,
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
                    self.applyPage(.entries(e.appending(items, requestedLimit: Self.pageSize)))
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
        entries.loadMore(scope: state.scope, filter: state.filter, before: cursor) { [weak self] outcome in
            guard let self, case .entries(let e) = self.page else { return }
            switch outcome {
            case .loaded(let items):
                self.applyPage(.entries(e.appending(items, requestedLimit: Self.pageSize)))
            case .failed:
                self.applyPage(.entries(e.failedLoad()))
            }
            self.updatePanelHeight()
        }
    }

    private func toggleFindDone(item: EntryListItem, in state: EntriesListPageState) {
        let target: Bin = item.bin == .done ? .inbox : .done
        let next = EntryListItem(id: item.id, text: item.text, bin: target, createdAt: item.createdAt, tags: item.tags)
        applyPage(.findResults(state.replacingSelected(with: next)))
        if target == .done || target == .trash { dropFromPreview(id: item.id) }
        moveDispatcher.send(entryId: item.id, toBin: target)
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
        case .tagSuggestions(let t):
            return tagAutocomplete.navigate(direction, in: t)
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
        case .findResults(let e):
            // The field stays active here, so ↑ at the top simply clamps; we don't exit the page.
            guard !e.list.isEmpty else { return false }
            let next: EntriesListPageState
            switch direction {
            case .down: next = e.cursorDown()
            case .up: next = e.cursorUp()
            case .pageDown: next = e.pageDown()
            case .pageUp: next = e.pageUp()
            }
            applyPage(.findResults(next))
            updatePanelHeight()
            if next.shouldLoadMore { liveFind.loadMore(from: next) }
            return true
        }
    }

    private func applyTagsLocally(entryId: UUID, applied: Set<String>) {
        guard case .entries(let e) = page else { return }
        guard let idx = e.list.items.firstIndex(where: { $0.id == entryId }) else { return }
        let item = e.list.items[idx]
        let newItem = EntryListItem(
            id: item.id,
            text: item.text,
            bin: item.bin,
            createdAt: item.createdAt,
            tags: applied.sorted()
        )
        applyPage(.entries(e.replacing(at: idx, with: newItem)))
    }

    private func installKeyMonitor() {
        uninstallKeyMonitor()
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return event }
            if event.modifierFlags.contains(.command) { return event }
            if self.tagEditCoordinator.isActive {
                return self.tagEditCoordinator.handleKey(event) ? nil : event
            }
            // 't' on a selected row opens tag edit. Intercept before the field eats it as text.
            if event.charactersIgnoringModifiers == "t",
               case .entries(let e) = self.page,
               let item = e.list.selected {
                self.tagEditCoordinator.enter(for: item)
                return nil
            }
            return event
        }
    }

    private func uninstallKeyMonitor() {
        if let monitor = keyMonitor {
            NSEvent.removeMonitor(monitor)
            keyMonitor = nil
        }
    }

    private func autocompleteSuggestion() -> Bool {
        switch page {
        case .suggestions(let s):
            guard let pick = s.selected else { return true }
            applyAutocomplete(token: pick.token)
            return true
        case .tagSuggestions(let t):
            guard let pick = t.selected else { return true }
            return acceptTagSuggestion(pick, in: t)
        default:
            return true
        }
    }

    private func applyAutocomplete(token: String) {
        layout.field.stringValue = token
        if let editor = layout.field.currentEditor() {
            let len = (token as NSString).length
            editor.selectedRange = NSRange(location: len, length: 0)
        }
        layout.field.refreshTokenHighlight()
        let next = SlashSuggestionState.empty(windowSize: windowSize).applying(text: token)
        applyPage(.suggestions(next))
        updatePanelHeight()
    }

    private func acceptTagSuggestion(_ pick: TagSuggestion, in state: TagSuggestionState) -> Bool {
        let result = tagAutocomplete.acceptSelection(pick, state: state, currentText: layout.field.stringValue)
        layout.field.stringValue = result.text
        if let editor = layout.field.currentEditor() {
            editor.selectedRange = NSRange(location: result.cursor, length: 0)
        }
        layout.field.refreshTokenHighlight()
        updatePanelHeight()
        // Programmatic stringValue changes don't fire controlTextDidChange, so re-trigger the
        // live /find dispatch when the accepted tag landed inside a find query.
        if LiveFindCoordinator.isFindContext(result.text) {
            liveFind.kickoff(raw: result.text)
        }
        return true
    }
}
