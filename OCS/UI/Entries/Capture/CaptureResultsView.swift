import AppKit

@MainActor
final class CaptureResultsView: NSStackView {
    init() {
        super.init(frame: .zero)
        orientation = .vertical
        alignment = .leading
        spacing = Applied.Capture.outputRowSpacing
        translatesAutoresizingMaskIntoConstraints = false
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    var isPopulated: Bool { !arrangedSubviews.isEmpty }

    func showLoading() { replace(with: [mutedLabel("loading...")]) }

    func showError() { replace(with: [mutedLabel("could not load entries")]) }

    func showItems(_ items: [EntryListItem]) {
        if items.isEmpty {
            replace(with: [mutedLabel("no entries yet")])
        } else {
            replace(with: items.map(EntryListItemRow.init(item:)))
        }
    }

    func showSuggestions(_ specs: [SlashCommand.Spec], selectedIndex: Int) {
        replace(with: specs.enumerated().map { SuggestionRow(spec: $0.element, selected: $0.offset == selectedIndex) })
    }

    func clear() { replace(with: []) }

    private func replace(with views: [NSView]) {
        for v in arrangedSubviews {
            removeArrangedSubview(v)
            v.removeFromSuperview()
        }
        for v in views {
            addArrangedSubview(v)
            v.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
        }
    }

    private func mutedLabel(_ text: String) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.font = Applied.Capture.outputFont
        label.textColor = Applied.Capture.outputEmptyColor
        return label
    }
}
