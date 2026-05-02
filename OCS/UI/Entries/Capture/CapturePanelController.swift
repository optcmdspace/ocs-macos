import AppKit
import Foundation

@MainActor
final class CapturePanelController: NSObject, NSTextFieldDelegate, NSWindowDelegate {
    private let panel: CapturePanel
    private let textField: CaptureField
    private let prompt: CapturePrompt
    private let footerHeight: CGFloat
    private let fieldHeightConstraint: NSLayoutConstraint
    private let dispatch: @Sendable (_ rawText: String) async throws -> UUID

    init(dispatch: @escaping @Sendable (_ rawText: String) async throws -> UUID) {
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

        background.addSubview(tint)
        background.addSubview(prompt)
        background.addSubview(field)
        background.addSubview(footer)

        let fieldHeight = field.heightAnchor.constraint(equalToConstant: lineHeight)

        NSLayoutConstraint.activate([
            prompt.leadingAnchor.constraint(equalTo: background.leadingAnchor, constant: Applied.Capture.horizontalPadding),
            prompt.firstBaselineAnchor.constraint(equalTo: field.firstBaselineAnchor),
            field.leadingAnchor.constraint(equalTo: prompt.trailingAnchor, constant: Applied.Capture.promptGap),
            field.trailingAnchor.constraint(equalTo: background.trailingAnchor, constant: -Applied.Capture.horizontalPadding),
            field.topAnchor.constraint(equalTo: background.topAnchor, constant: Applied.Capture.verticalPadding),
            fieldHeight,
            footer.topAnchor.constraint(equalTo: field.bottomAnchor, constant: Applied.Capture.footerGap),
            footer.trailingAnchor.constraint(equalTo: background.trailingAnchor, constant: -Applied.Capture.horizontalPadding),
            footer.bottomAnchor.constraint(equalTo: background.bottomAnchor, constant: -Applied.Capture.footerBottomInset),
        ])

        panel.contentView = background

        self.panel = panel
        self.textField = field
        self.prompt = prompt
        self.footerHeight = footerHeight
        self.fieldHeightConstraint = fieldHeight
        self.dispatch = dispatch

        super.init()

        field.delegate = self
        panel.delegate = self
        panel.onCancel = { [weak self] in self?.dismiss() }
    }

    func controlTextDidChange(_ obj: Notification) {
        updatePanelHeight()
    }

    func windowDidResignKey(_ notification: Notification) {
        dismiss()
    }

    func show() {
        textField.stringValue = ""
        resetPanelHeight()
        position()
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
        panel.makeFirstResponder(textField)
    }

    private func lineHeight() -> CGFloat {
        ceil(Applied.Capture.bodyFont.boundingRectForFont.height)
    }

    private func panelHeight(forFieldHeight fieldHeight: CGFloat) -> CGFloat {
        Applied.Capture.verticalPadding
            + fieldHeight
            + Applied.Capture.footerGap
            + footerHeight
            + Applied.Capture.footerBottomInset
    }

    private func resetPanelHeight() {
        let h = lineHeight()
        fieldHeightConstraint.constant = h
        setPanelHeight(panelHeight(forFieldHeight: h))
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
        setPanelHeight(panelHeight(forFieldHeight: fieldH))
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
        let text = textField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            dismiss()
            return
        }
        let dispatch = self.dispatch
        Task.detached {
            do {
                _ = try await dispatch(text)
            } catch {
                NSLog("OCS: capture failed: %@", String(describing: error))
            }
        }
        textField.stringValue = ""
        dismiss()
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
        case #selector(NSResponder.insertTab(_:)),
             #selector(NSResponder.insertBacktab(_:)):
            return true
        default:
            return false
        }
    }
}
