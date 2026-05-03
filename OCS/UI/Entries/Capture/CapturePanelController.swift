import AppKit
import Foundation

@MainActor
final class CapturePanelController: NSObject, NSTextFieldDelegate, NSWindowDelegate {
    private static let listLimit: Int = 10

    private let panel: CapturePanel
    private let textField: CaptureField
    private let prompt: CapturePrompt
    private let results: CaptureResultsView
    private let footerHeight: CGFloat
    private let fieldHeightConstraint: NSLayoutConstraint
    private let resultsTopConstraint: NSLayoutConstraint
    private let dispatchCapture: @Sendable (_ rawText: String) async throws -> UUID
    private let dispatchListRecent: @Sendable (_ limit: Int) async throws -> [EntryListItem]
    // Bumped on submit and on every keystroke so an in-flight result never overwrites stale state.
    private var listGeneration: Int = 0
    private var suggestions: SlashSuggestionState = .empty

    init(
        dispatchCapture: @escaping @Sendable (_ rawText: String) async throws -> UUID,
        dispatchListRecent: @escaping @Sendable (_ limit: Int) async throws -> [EntryListItem]
    ) {
        let lineHeight = ceil(Applied.Capture.bodyFont.boundingRectForFont.height)
        let footerHeight = ceil(Applied.Capture.captionFont.boundingRectForFont.height)
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
        let results = CaptureResultsView()

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
            footer.trailingAnchor.constraint(equalTo: background.trailingAnchor, constant: -Applied.Capture.horizontalPadding),
            footer.bottomAnchor.constraint(equalTo: background.bottomAnchor, constant: -Applied.Capture.footerBottomInset),
        ])

        panel.contentView = background

        self.panel = panel
        self.textField = field
        self.prompt = prompt
        self.results = results
        self.footerHeight = footerHeight
        self.fieldHeightConstraint = fieldHeight
        self.resultsTopConstraint = resultsTop
        self.dispatchCapture = dispatchCapture
        self.dispatchListRecent = dispatchListRecent

        super.init()

        field.delegate = self
        panel.delegate = self
        panel.onCancel = { [weak self] in self?.dismiss() }
    }

    func controlTextDidChange(_ obj: Notification) {
        listGeneration &+= 1
        applySuggestions(suggestions.applying(text: textField.stringValue))
        updatePanelHeight()
    }

    private func applySuggestions(_ next: SlashSuggestionState) {
        suggestions = next
        if next.isEmpty {
            if results.isPopulated { clearResults() }
            return
        }
        results.showSuggestions(next.items, selectedIndex: next.selectedIndex)
        resultsTopConstraint.constant = Applied.Capture.outputTopGap
    }

    func windowDidResignKey(_ notification: Notification) {
        dismiss()
    }

    func show() {
        textField.stringValue = ""
        suggestions = .empty
        clearResults()
        listGeneration &+= 1
        resetPanelHeight()
        position()
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
        panel.makeFirstResponder(textField)
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

    func dismiss() {
        panel.orderOut(nil)
    }

    func toggle() {
        if panel.isVisible {
            dismiss()
        } else {
            show()
        }
    }

    private func commit() {
        let raw = suggestions.selected?.token ?? textField.stringValue
        suggestions = .empty
        switch SlashCommand.parse(raw) {
        case .list:
            textField.stringValue = ""
            fetchAndShowList()
        case .capture(let text):
            guard !text.isEmpty else {
                dismiss()
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
            dismiss()
        }
    }

    private func fetchAndShowList() {
        listGeneration &+= 1
        let myGen = listGeneration
        results.showLoading()
        resultsTopConstraint.constant = Applied.Capture.outputTopGap
        updatePanelHeight()

        let dispatchListRecent = self.dispatchListRecent
        let limit = Self.listLimit
        Task { [weak self] in
            do {
                let items = try await dispatchListRecent(limit)
                guard let self, self.listGeneration == myGen else { return }
                self.results.showItems(items)
                self.updatePanelHeight()
            } catch {
                NSLog("OCS: list query failed: %@", String(describing: error))
                guard let self, self.listGeneration == myGen else { return }
                self.results.showError()
                self.updatePanelHeight()
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
            commit()
            return true
        case #selector(NSResponder.moveDown(_:)):
            guard !suggestions.isEmpty else { return false }
            applySuggestions(suggestions.movedDown())
            return true
        case #selector(NSResponder.moveUp(_:)):
            guard !suggestions.isEmpty else { return false }
            applySuggestions(suggestions.movedUp())
            return true
        case #selector(NSResponder.insertTab(_:)):
            if let pick = suggestions.selected {
                textField.stringValue = pick.token
                applySuggestions(suggestions.applying(text: pick.token))
                updatePanelHeight()
            }
            return true
        case #selector(NSResponder.insertBacktab(_:)):
            return true
        default:
            return false
        }
    }
}
