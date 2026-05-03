import AppKit
import Foundation

@MainActor
final class CapturePanelController: NSObject, NSTextFieldDelegate, NSWindowDelegate {
    private static let pageSize: Int = 20
    private let windowSize: Int = Applied.Capture.terminalDefaultWindowSize

    private let panel: CapturePanel
    private let textField: CaptureField
    private let prompt: CapturePrompt
    private let results: TerminalView
    private let footer: CaptureFooter
    private let footerHeight: CGFloat
    private let fieldHeightConstraint: NSLayoutConstraint
    private let resultsTopConstraint: NSLayoutConstraint
    private let dispatchCapture: @Sendable (_ rawText: String) async throws -> UUID
    private let dispatchListRecent: @Sendable (_ limit: Int, _ scope: ListRecentEntriesQuery.Scope, _ before: ListRecentEntriesQuery.Cursor?) async throws -> [EntryListItem]
    private let dispatchMove: @Sendable (_ entryId: UUID, _ toBin: Bin) async throws -> Void
    // Bumped on submit and on every keystroke so an in-flight result never overwrites stale state.
    private var listGeneration: Int = 0
    private var page: PageMode = .idle

    private enum PageMode: Equatable {
        case idle
        case suggestions(SlashSuggestionState)
        case entries(EntriesListPageState)
    }

    private enum NavDirection {
        case down, up, pageDown, pageUp
    }

    init(
        dispatchCapture: @escaping @Sendable (_ rawText: String) async throws -> UUID,
        dispatchListRecent: @escaping @Sendable (_ limit: Int, _ scope: ListRecentEntriesQuery.Scope, _ before: ListRecentEntriesQuery.Cursor?) async throws -> [EntryListItem],
        dispatchMove: @escaping @Sendable (_ entryId: UUID, _ toBin: Bin) async throws -> Void
    ) {
        let lineHeight = ceil(Applied.Capture.bodyFont.boundingRectForFont.height)
        let footerHeight = ceil(Applied.Capture.shortcutKeyFont.boundingRectForFont.height)
        let initialHeight = Applied.Capture.verticalPadding
            + lineHeight
            + Applied.Capture.footerGap
            + footerHeight
            + Applied.Capture.footerBottomInset
        let size = NSSize(width: Applied.Capture.panelWidth, height: initialHeight)
        let rect = NSRect(origin: .zero, size: size)

        let panel = CapturePanel(contentRect: rect)

        let background: NSVisualEffectView = {
            let v = NSVisualEffectView(frame: rect)
            v.material = .hudWindow
            v.blendingMode = .behindWindow
            v.state = .active
            v.wantsLayer = true
            v.layer?.cornerRadius = Applied.Capture.cornerRadius
            v.layer?.masksToBounds = true
            v.layer?.borderWidth = Applied.Capture.borderWidth
            v.layer?.borderColor = Applied.Capture.borderColor.cgColor
            v.autoresizingMask = [.width, .height]
            return v
        }()

        let tint: NSView = {
            let v = NSView(frame: rect)
            v.wantsLayer = true
            v.layer?.backgroundColor = Applied.Capture.tintColor.cgColor
            v.autoresizingMask = [.width, .height]
            return v
        }()

        let prompt = CapturePrompt()
        let field = CaptureField()
        let footer = CaptureFooter()
        let results = TerminalView()

        background.addSubview(tint)
        background.addSubview(prompt)
        background.addSubview(field)
        background.addSubview(results)
        background.addSubview(footer)

        let fieldHeight = field.heightAnchor.constraint(equalToConstant: lineHeight)
        let resultsTop = results.topAnchor.constraint(equalTo: field.bottomAnchor, constant: 0)

        NSLayoutConstraint.activate([
            prompt.leadingAnchor.constraint(equalTo: background.leadingAnchor, constant: Applied.Capture.horizontalPadding),
            prompt.firstBaselineAnchor.constraint(equalTo: field.firstBaselineAnchor),
            field.leadingAnchor.constraint(equalTo: prompt.trailingAnchor, constant: Applied.Capture.promptGap),
            field.trailingAnchor.constraint(equalTo: background.trailingAnchor, constant: -Applied.Capture.horizontalPadding),
            field.topAnchor.constraint(equalTo: background.topAnchor, constant: Applied.Capture.verticalPadding),
            fieldHeight,
            results.leadingAnchor.constraint(equalTo: background.leadingAnchor, constant: Applied.Capture.horizontalPadding),
            results.trailingAnchor.constraint(equalTo: background.trailingAnchor, constant: -Applied.Capture.horizontalPadding),
            resultsTop,
            footer.topAnchor.constraint(equalTo: results.bottomAnchor, constant: Applied.Capture.footerGap),
            footer.leadingAnchor.constraint(equalTo: background.leadingAnchor, constant: Applied.Capture.horizontalPadding),
            footer.trailingAnchor.constraint(equalTo: background.trailingAnchor, constant: -Applied.Capture.horizontalPadding),
            footer.bottomAnchor.constraint(equalTo: background.bottomAnchor, constant: -Applied.Capture.footerBottomInset),
        ])

        panel.contentView = background

        self.panel = panel
        self.textField = field
        self.prompt = prompt
        self.results = results
        self.footer = footer
        self.footerHeight = footerHeight
        self.fieldHeightConstraint = fieldHeight
        self.resultsTopConstraint = resultsTop
        self.dispatchCapture = dispatchCapture
        self.dispatchListRecent = dispatchListRecent
        self.dispatchMove = dispatchMove

        super.init()

        field.delegate = self
        panel.delegate = self
        panel.onCancel = { [weak self] in self?.dismiss() }
        refreshFooter()
    }

    func controlTextDidChange(_ obj: Notification) {
        listGeneration &+= 1
        let current: SlashSuggestionState = {
            if case .suggestions(let s) = page { return s }
            return .empty(windowSize: windowSize)
        }()
        applyPage(.suggestions(current.applying(text: textField.stringValue)))
        updatePanelHeight()
    }

    func windowDidResignKey(_ notification: Notification) {
        dismiss()
    }

    func show() {
        textField.stringValue = ""
        page = .idle
        clearResults()
        listGeneration &+= 1
        resetPanelHeight()
        refreshFooter()
        position()
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
        panel.makeFirstResponder(textField)
    }

    func dismiss() {
        page = .idle
        panel.orderOut(nil)
    }

    func toggle() {
        if panel.isVisible {
            dismiss()
        } else {
            show()
        }
    }

    private func applyPage(_ next: PageMode) {
        var normalized = next
        if case .suggestions(let s) = next, s.isEmpty {
            normalized = .idle
        }
        page = normalized
        render()
        refreshFooter()
    }

    private func refreshFooter() {
        let hints: [(key: String, label: String)]
        switch page {
        case .idle:
            if textField.stringValue.isEmpty {
                hints = [("↓", "for list")]
            } else {
                hints = [("⏎", "to submit"), ("⇧⏎", "to submit and continue")]
            }
        case .suggestions:
            hints = [("↑↓", "to navigate"), ("⇥", "to complete"), ("⏎", "to run")]
        case .entries(let e):
            if e.list.isEmpty {
                hints = [("↑", "to go back")]
            } else {
                let enterLabel = e.list.selected?.bin == .done ? "to undo done" : "to mark done"
                hints = [("↑↓", "to navigate"), ("⏎", enterLabel), ("⌫", "to delete")]
            }
        }
        footer.setHints(hints)
    }

    private func render() {
        switch page {
        case .idle:
            if results.isPopulated { clearResults() }
            return
        case .suggestions(let s):
            results.setRows(s.list.renderedRows(CaptureRows.suggestion))
        case .entries(let e):
            if e.list.isEmpty {
                if e.isLoadingMore {
                    results.setRows([.message("loading...")])
                } else if e.hasError {
                    results.setRows([.message("could not load entries")])
                } else {
                    results.setRows([.message("no entries yet")])
                }
            } else {
                let now = Date()
                let minWidth = Applied.Capture.outputTimestampMinWidth
                results.setRows(e.list.renderedRows {
                    CaptureRows.entry($0, now: now, trailingMinWidth: minWidth)
                })
            }
        }
        resultsTopConstraint.constant = Applied.Capture.outputTopGap
    }

    private func lineHeight() -> CGFloat {
        ceil(Applied.Capture.bodyFont.boundingRectForFont.height)
    }

    private func panelHeight(fieldHeight: CGFloat, outputHeight: CGFloat) -> CGFloat {
        let outputContribution = outputHeight > 0
            ? Applied.Capture.outputTopGap + outputHeight
            : 0
        return Applied.Capture.verticalPadding
            + fieldHeight
            + outputContribution
            + Applied.Capture.footerGap
            + footerHeight
            + Applied.Capture.footerBottomInset
    }

    private func currentOutputHeight() -> CGFloat {
        guard results.isPopulated else { return 0 }
        results.layoutSubtreeIfNeeded()
        return ceil(results.fittingSize.height)
    }

    private func resetPanelHeight() {
        let h = lineHeight()
        fieldHeightConstraint.constant = h
        setPanelHeight(panelHeight(fieldHeight: h, outputHeight: currentOutputHeight()))
    }

    private func updatePanelHeight() {
        let promptWidth = ceil(prompt.intrinsicContentSize.width)
        let availableWidth = Applied.Capture.panelWidth - 2 * Applied.Capture.horizontalPadding - promptWidth - Applied.Capture.promptGap
        guard availableWidth > 0 else { return }
        let text = textField.stringValue.isEmpty ? " " : textField.stringValue
        let bounding = (text as NSString).boundingRect(
            with: NSSize(width: availableWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: Applied.Capture.bodyFont]
        )
        let fieldH = max(lineHeight(), ceil(bounding.height))
        fieldHeightConstraint.constant = fieldH
        setPanelHeight(panelHeight(fieldHeight: fieldH, outputHeight: currentOutputHeight()))
    }

    private func setPanelHeight(_ newHeight: CGFloat) {
        let current = panel.frame
        if abs(current.height - newHeight) < 0.5 { return }
        let newY = current.maxY - newHeight
        panel.setFrame(
            NSRect(x: current.origin.x, y: newY, width: current.width, height: newHeight),
            display: true,
            animate: false
        )
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
            raw = textField.stringValue
        }
        switch SlashCommand.parse(raw) {
        case .list(let scope):
            textField.stringValue = ""
            beginEntriesLoad(scope: scope)
        case .capture(let text):
            guard !text.isEmpty else {
                if !keepOpen { dismiss() }
                return
            }
            let dispatchCapture = self.dispatchCapture
            Task.detached {
                do {
                    _ = try await dispatchCapture(text)
                } catch {
                    NSLog("OCS: capture failed: %@", String(describing: error))
                }
            }
            textField.stringValue = ""
            if keepOpen {
                listGeneration &+= 1
                applyPage(.idle)
                updatePanelHeight()
            } else {
                dismiss()
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
        dispatchMoveDetached(entryId: item.id, toBin: bin)
    }

    private func trashSelected(item: EntryListItem, in state: EntriesListPageState) {
        applyPage(.entries(state.removingSelected()))
        updatePanelHeight()
        dispatchMoveDetached(entryId: item.id, toBin: .trash)
    }

    private func dispatchMoveDetached(entryId: UUID, toBin: Bin) {
        let dispatchMove = self.dispatchMove
        Task.detached {
            do {
                try await dispatchMove(entryId, toBin)
            } catch {
                NSLog("OCS: move failed: %@", String(describing: error))
            }
        }
    }

    private func beginEntriesLoad(scope: ListRecentEntriesQuery.Scope) {
        listGeneration &+= 1
        let myGen = listGeneration
        let initial = EntriesListPageState.empty(windowSize: windowSize, scope: scope).startingLoad()
        applyPage(.entries(initial))
        updatePanelHeight()

        let dispatchListRecent = self.dispatchListRecent
        let pageSize = Self.pageSize
        Task { [weak self] in
            do {
                let items = try await dispatchListRecent(pageSize, scope, nil)
                guard let self, self.listGeneration == myGen else { return }
                if case .entries(let e) = self.page {
                    self.applyPage(.entries(e.appending(items)))
                    self.updatePanelHeight()
                }
            } catch {
                NSLog("OCS: list query failed: %@", String(describing: error))
                guard let self, self.listGeneration == myGen else { return }
                if case .entries(let e) = self.page {
                    self.applyPage(.entries(e.failedLoad()))
                    self.updatePanelHeight()
                }
            }
        }
    }

    private func loadMoreEntries(from state: EntriesListPageState) {
        guard let cursor = state.nextCursor else { return }
        let myGen = listGeneration
        let scope = state.scope
        applyPage(.entries(state.startingLoad()))

        let dispatchListRecent = self.dispatchListRecent
        let pageSize = Self.pageSize
        Task { [weak self] in
            do {
                let more = try await dispatchListRecent(pageSize, scope, cursor)
                guard let self, self.listGeneration == myGen else { return }
                if case .entries(let e) = self.page {
                    self.applyPage(.entries(e.appending(more)))
                    self.updatePanelHeight()
                }
            } catch {
                NSLog("OCS: list page query failed: %@", String(describing: error))
                guard let self, self.listGeneration == myGen else { return }
                if case .entries(let e) = self.page {
                    self.applyPage(.entries(e.failedLoad()))
                    self.updatePanelHeight()
                }
            }
        }
    }

    private func clearResults() {
        results.clear()
        resultsTopConstraint.constant = 0
    }

    private func position() {
        guard let screen = NSScreen.main else { return }
        let visible = screen.visibleFrame
        let size = panel.frame.size
        let origin = NSPoint(
            x: visible.midX - size.width / 2,
            y: visible.maxY - size.height - visible.height * 0.28
        )
        panel.setFrameOrigin(origin)
    }

    func control(
        _ control: NSControl,
        textView: NSTextView,
        doCommandBy commandSelector: Selector
    ) -> Bool {
        switch commandSelector {
        case #selector(NSResponder.cancelOperation(_:)):
            dismiss()
            return true
        case #selector(NSResponder.insertNewline(_:)):
            let shift = NSApp.currentEvent?.modifierFlags.contains(.shift) ?? false
            commit(keepOpen: shift)
            return true
        case #selector(NSResponder.insertLineBreak(_:)):
            commit(keepOpen: true)
            return true
        case #selector(NSResponder.moveDown(_:)):
            return navigate(.down)
        case #selector(NSResponder.moveUp(_:)):
            return navigate(.up)
        case #selector(NSResponder.scrollPageDown(_:)),
             #selector(NSResponder.pageDown(_:)):
            return navigate(.pageDown)
        case #selector(NSResponder.scrollPageUp(_:)),
             #selector(NSResponder.pageUp(_:)):
            return navigate(.pageUp)
        case #selector(NSResponder.insertTab(_:)):
            return autocompleteSuggestion()
        case #selector(NSResponder.insertBacktab(_:)):
            return true
        case #selector(NSResponder.deleteBackward(_:)):
            return handleBackspaceInEntries()
        default:
            return false
        }
    }

    private func navigate(_ direction: NavDirection) -> Bool {
        switch page {
        case .idle:
            if direction == .down && textField.stringValue.isEmpty {
                beginEntriesLoad(scope: .active)
                return true
            }
            return false
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
                listGeneration &+= 1
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
        textField.stringValue = pick.token
        applyPage(.suggestions(s.applying(text: pick.token)))
        updatePanelHeight()
        return true
    }
}
