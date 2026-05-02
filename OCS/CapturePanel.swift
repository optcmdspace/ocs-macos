//
//  CapturePanel.swift
//  OCS
//

import AppKit

@MainActor
final class CapturePanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

@MainActor
final class CapturePanelController: NSObject, NSTextFieldDelegate {
    private let panel: CapturePanel
    private let textField: NSTextField

    override init() {
        let size = NSSize(width: 640, height: 60)
        let rect = NSRect(origin: .zero, size: size)
        let font = NSFont.monospacedSystemFont(ofSize: 18, weight: .regular)

        let panel: CapturePanel = {
            let p = CapturePanel(
                contentRect: rect,
                styleMask: [.borderless, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            p.level = .floating
            p.isFloatingPanel = true
            p.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
            p.hidesOnDeactivate = false
            p.isMovableByWindowBackground = false
            p.backgroundColor = .clear
            p.isOpaque = false
            p.hasShadow = true
            p.titleVisibility = .hidden
            p.titlebarAppearsTransparent = true
            return p
        }()

        let background: NSVisualEffectView = {
            let v = NSVisualEffectView(frame: rect)
            v.material = .hudWindow
            v.blendingMode = .behindWindow
            v.state = .active
            v.wantsLayer = true
            v.layer?.cornerRadius = 10
            v.layer?.masksToBounds = true
            v.layer?.borderWidth = 1
            v.layer?.borderColor = NSColor.white.withAlphaComponent(0.08).cgColor
            v.autoresizingMask = [.width, .height]
            return v
        }()

        let prompt: NSTextField = {
            let label = NSTextField(labelWithString: "❯")
            label.font = font
            label.textColor = NSColor.secondaryLabelColor
            label.translatesAutoresizingMaskIntoConstraints = false
            return label
        }()

        let field: NSTextField = {
            let f = NSTextField()
            f.isBezeled = false
            f.isBordered = false
            f.drawsBackground = false
            f.focusRingType = .none
            f.font = font
            f.textColor = NSColor.labelColor
            f.placeholderAttributedString = NSAttributedString(
                string: "capture",
                attributes: [
                    .font: font,
                    .foregroundColor: NSColor.tertiaryLabelColor,
                ]
            )
            f.translatesAutoresizingMaskIntoConstraints = false
            return f
        }()

        background.addSubview(prompt)
        background.addSubview(field)

        NSLayoutConstraint.activate([
            prompt.leadingAnchor.constraint(equalTo: background.leadingAnchor, constant: 20),
            prompt.centerYAnchor.constraint(equalTo: background.centerYAnchor),
            field.leadingAnchor.constraint(equalTo: prompt.trailingAnchor, constant: 12),
            field.trailingAnchor.constraint(equalTo: background.trailingAnchor, constant: -20),
            field.centerYAnchor.constraint(equalTo: background.centerYAnchor),
        ])

        panel.contentView = background

        self.panel = panel
        self.textField = field

        super.init()

        field.delegate = self
    }

    func show() {
        textField.stringValue = ""
        position()
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
        panel.makeFirstResponder(textField)
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
        // TODO: persist via the event.
        NSLog("captured: %@", text)
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
