import AppKit

@MainActor
final class TerminalView: NSStackView {
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

    func setRows(_ specs: [TerminalRow.Spec]) {
        clearArranged()
        for spec in specs {
            let row = TerminalRowView(spec: spec)
            addArrangedSubview(row)
            row.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
        }
    }

    func setLoading() {
        clearArranged()
        let row = TerminalLoadingRow()
        addArrangedSubview(row)
        row.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
    }

    func clear() { clearArranged() }

    private func clearArranged() {
        for v in arrangedSubviews {
            removeArrangedSubview(v)
            v.removeFromSuperview()
        }
    }
}
