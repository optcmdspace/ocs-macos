import AppKit

extension CapturePanelLayout {
    func panelHeight(fieldHeight: CGFloat, outputHeight: CGFloat, glanceVisible: Bool) -> CGFloat {
        let glanceContribution = glanceVisible ? glanceLineHeight + Applied.Capture.glanceBottomGap : 0
        let outputContribution = outputHeight > 0
            ? Applied.Capture.outputTopGap
                + Applied.Capture.dividerHeight
                + Applied.Capture.outputTopGap
                + outputHeight
            : 0
        return Applied.Capture.verticalPadding
            + glanceContribution
            + fieldHeight
            + outputContribution
            + Applied.Capture.footerGap
            + footerHeight
            + Applied.Capture.footerBottomInset
    }

    func currentOutputHeight() -> CGFloat {
        guard results.isPopulated else { return 0 }
        results.layoutSubtreeIfNeeded()
        return ceil(results.fittingSize.height)
    }

    func setPanelHeight(_ newHeight: CGFloat) {
        let current = panel.frame
        if abs(current.height - newHeight) < 0.5 { return }
        let newY = current.maxY - newHeight
        panel.setFrame(
            NSRect(x: current.origin.x, y: newY, width: current.width, height: newHeight),
            display: true,
            animate: false
        )
    }

    func resetPanelHeight(glanceVisible: Bool) {
        let h = lineHeight
        fieldHeightConstraint.constant = h
        setPanelHeight(panelHeight(fieldHeight: h, outputHeight: currentOutputHeight(), glanceVisible: glanceVisible))
    }

    func updatePanelHeight(forText text: String, glanceVisible: Bool) {
        let promptWidth = ceil(prompt.intrinsicContentSize.width)
        let availableWidth = Applied.Capture.panelWidth - 2 * Applied.Capture.horizontalPadding - promptWidth - Applied.Capture.promptGap
        guard availableWidth > 0 else { return }
        let probe = text.isEmpty ? " " : text
        let bounding = (probe as NSString).boundingRect(
            with: NSSize(width: availableWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: Applied.Capture.bodyFont]
        )
        let fieldH = max(lineHeight, ceil(bounding.height))
        fieldHeightConstraint.constant = fieldH
        setPanelHeight(panelHeight(fieldHeight: fieldH, outputHeight: currentOutputHeight(), glanceVisible: glanceVisible))
    }

    func showDivider(_ visible: Bool) {
        divider.isHidden = !visible
        let gap = visible ? Applied.Capture.outputTopGap : 0
        dividerTopConstraint.constant = gap
        resultsTopConstraint.constant = gap
    }

    func clearResults() {
        results.clear()
        showDivider(false)
    }

    func position() {
        guard let screen = NSScreen.main else { return }
        let visible = screen.visibleFrame
        let size = panel.frame.size
        let origin = NSPoint(
            x: visible.midX - size.width / 2,
            y: visible.maxY - size.height - visible.height * 0.28
        )
        panel.setFrameOrigin(origin)
    }
}
