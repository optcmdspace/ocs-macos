import AppKit

@MainActor
struct CapturePanelLayout {
    let panel: CapturePanel
    let prompt: CapturePrompt
    let field: CaptureField
    let footer: CaptureFooter
    let results: TerminalView
    let divider: NSView
    let glance: NSTextField
    let tagPicker: NSTextField

    let fieldHeightConstraint: NSLayoutConstraint
    let glanceHeightConstraint: NSLayoutConstraint
    let glanceBottomGapConstraint: NSLayoutConstraint
    let dividerTopConstraint: NSLayoutConstraint
    let resultsTopConstraint: NSLayoutConstraint
    let tagPickerHeightConstraint: NSLayoutConstraint
    let tagPickerTopConstraint: NSLayoutConstraint

    let lineHeight: CGFloat
    let footerHeight: CGFloat
    let glanceLineHeight: CGFloat
    let tagPickerHeight: CGFloat

    static func build() -> CapturePanelLayout {
        let lineHeight = ceil(Applied.Capture.bodyFont.boundingRectForFont.height)
        let footerHeight = ceil(Applied.Capture.shortcutKeyFont.boundingRectForFont.height)
        let glanceLineHeight = ceil(Applied.Capture.glanceFont.boundingRectForFont.height)
        let tagPickerHeight = ceil(Applied.Capture.outputTagsFont.boundingRectForFont.height) + 4
        let initialHeight = Applied.Capture.verticalPadding
            + lineHeight
            + Applied.Capture.footerGap
            + footerHeight
            + Applied.Capture.footerBottomInset
        let size = NSSize(width: Applied.Capture.panelWidth, height: initialHeight)
        let rect = NSRect(origin: .zero, size: size)

        let panel = CapturePanel(contentRect: rect)

        let background = NSVisualEffectView(frame: rect)
        background.material = .hudWindow
        background.blendingMode = .behindWindow
        background.state = .active
        background.wantsLayer = true
        background.layer?.cornerRadius = Applied.Capture.cornerRadius
        background.layer?.cornerCurve = .continuous
        background.layer?.masksToBounds = true
        background.layer?.borderWidth = Applied.Capture.borderWidth
        background.layer?.borderColor = Applied.Capture.borderColor.cgColor
        background.autoresizingMask = [.width, .height]

        let tint = NSView(frame: rect)
        tint.wantsLayer = true
        tint.layer?.backgroundColor = Applied.Capture.tintColor.cgColor
        tint.autoresizingMask = [.width, .height]

        let prompt = CapturePrompt()
        let field = CaptureField()
        let footer = CaptureFooter()
        let results = TerminalView()

        let glance = NSTextField(labelWithString: "")
        glance.font = Applied.Capture.glanceFont
        glance.textColor = Applied.Capture.glanceColor
        glance.translatesAutoresizingMaskIntoConstraints = false
        glance.isHidden = true
        glance.alphaValue = 0
        glance.lineBreakMode = .byTruncatingTail

        let divider = NSView()
        divider.wantsLayer = true
        divider.layer?.backgroundColor = Applied.Capture.dividerColor.cgColor
        divider.translatesAutoresizingMaskIntoConstraints = false
        divider.isHidden = true

        let tagPicker = NSTextField(labelWithString: "")
        tagPicker.translatesAutoresizingMaskIntoConstraints = false
        tagPicker.lineBreakMode = .byWordWrapping
        tagPicker.maximumNumberOfLines = 0
        tagPicker.cell?.wraps = true
        tagPicker.cell?.isScrollable = false
        tagPicker.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        tagPicker.isHidden = true

        background.addSubview(tint)
        background.addSubview(glance)
        background.addSubview(prompt)
        background.addSubview(field)
        background.addSubview(divider)
        background.addSubview(results)
        background.addSubview(tagPicker)
        background.addSubview(footer)

        let fieldHeight = field.heightAnchor.constraint(equalToConstant: lineHeight)
        let glanceHeight = glance.heightAnchor.constraint(equalToConstant: 0)
        let glanceBottomGap = field.topAnchor.constraint(equalTo: glance.bottomAnchor, constant: 0)
        let dividerTop = divider.topAnchor.constraint(equalTo: field.bottomAnchor, constant: 0)
        let resultsTop = results.topAnchor.constraint(equalTo: divider.bottomAnchor, constant: 0)
        let tagPickerHeightC = tagPicker.heightAnchor.constraint(equalToConstant: 0)
        let tagPickerTop = tagPicker.topAnchor.constraint(equalTo: results.bottomAnchor, constant: 0)

        NSLayoutConstraint.activate([
            glance.topAnchor.constraint(equalTo: background.topAnchor, constant: Applied.Capture.verticalPadding),
            glance.leadingAnchor.constraint(equalTo: background.leadingAnchor, constant: Applied.Capture.horizontalPadding),
            glance.trailingAnchor.constraint(equalTo: background.trailingAnchor, constant: -Applied.Capture.horizontalPadding),
            glanceHeight,
            glanceBottomGap,
            prompt.leadingAnchor.constraint(equalTo: background.leadingAnchor, constant: Applied.Capture.horizontalPadding),
            prompt.firstBaselineAnchor.constraint(equalTo: field.firstBaselineAnchor),
            field.leadingAnchor.constraint(equalTo: prompt.trailingAnchor, constant: Applied.Capture.promptGap),
            field.trailingAnchor.constraint(equalTo: background.trailingAnchor, constant: -Applied.Capture.horizontalPadding),
            fieldHeight,
            divider.leadingAnchor.constraint(equalTo: background.leadingAnchor, constant: Applied.Capture.horizontalPadding),
            divider.trailingAnchor.constraint(equalTo: background.trailingAnchor, constant: -Applied.Capture.horizontalPadding),
            divider.heightAnchor.constraint(equalToConstant: Applied.Capture.dividerHeight),
            dividerTop,
            results.leadingAnchor.constraint(equalTo: background.leadingAnchor, constant: Applied.Capture.horizontalPadding),
            results.trailingAnchor.constraint(equalTo: background.trailingAnchor, constant: -Applied.Capture.horizontalPadding),
            resultsTop,
            tagPicker.leadingAnchor.constraint(equalTo: background.leadingAnchor, constant: Applied.Capture.horizontalPadding),
            tagPicker.trailingAnchor.constraint(equalTo: background.trailingAnchor, constant: -Applied.Capture.horizontalPadding),
            tagPickerTop,
            tagPickerHeightC,
            footer.topAnchor.constraint(equalTo: tagPicker.bottomAnchor, constant: Applied.Capture.footerGap),
            footer.leadingAnchor.constraint(equalTo: background.leadingAnchor, constant: Applied.Capture.horizontalPadding),
            footer.trailingAnchor.constraint(equalTo: background.trailingAnchor, constant: -Applied.Capture.horizontalPadding),
            footer.bottomAnchor.constraint(equalTo: background.bottomAnchor, constant: -Applied.Capture.footerBottomInset),
        ])

        panel.contentView = background

        return CapturePanelLayout(
            panel: panel,
            prompt: prompt,
            field: field,
            footer: footer,
            results: results,
            divider: divider,
            glance: glance,
            tagPicker: tagPicker,
            fieldHeightConstraint: fieldHeight,
            glanceHeightConstraint: glanceHeight,
            glanceBottomGapConstraint: glanceBottomGap,
            dividerTopConstraint: dividerTop,
            resultsTopConstraint: resultsTop,
            tagPickerHeightConstraint: tagPickerHeightC,
            tagPickerTopConstraint: tagPickerTop,
            lineHeight: lineHeight,
            footerHeight: footerHeight,
            glanceLineHeight: glanceLineHeight,
            tagPickerHeight: tagPickerHeight
        )
    }
}
