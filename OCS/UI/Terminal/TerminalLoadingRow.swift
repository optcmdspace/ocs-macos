import AppKit
import QuartzCore

@MainActor
final class TerminalLoadingRow: NSView {
    private let dots: [NSTextField]
    private var animating: Bool = false

    init() {
        let labels: [NSTextField] = (0..<3).map { _ in
            let label = NSTextField(labelWithString: "·")
            label.font = Applied.Capture.outputFont
            label.textColor = Applied.Capture.loadingDotColor
            label.translatesAutoresizingMaskIntoConstraints = false
            label.wantsLayer = true
            label.layer?.opacity = Float(Applied.Capture.loadingDotMinAlpha)
            return label
        }
        self.dots = labels
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false

        let indent = Applied.Capture.terminalMarkerWidth + Applied.Capture.terminalMarkerGap
        let first = labels[0]
        addSubview(first)
        NSLayoutConstraint.activate([
            first.leadingAnchor.constraint(equalTo: leadingAnchor, constant: indent),
            first.topAnchor.constraint(equalTo: topAnchor),
            first.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])

        // Remaining dots align to the first dot's baseline so all three sit on a single line of text.
        for i in 1..<labels.count {
            let dot = labels[i]
            addSubview(dot)
            NSLayoutConstraint.activate([
                dot.leadingAnchor.constraint(
                    equalTo: labels[i - 1].trailingAnchor,
                    constant: Applied.Capture.loadingDotSpacing
                ),
                dot.firstBaselineAnchor.constraint(equalTo: first.firstBaselineAnchor),
            ])
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if window != nil {
            startAnimating()
        } else {
            stopAnimating()
        }
    }

    private func startAnimating() {
        guard !animating else { return }
        animating = true
        let period = Applied.Capture.loadingDotPeriod
        let phase = period / Double(dots.count + 1)
        let now = CACurrentMediaTime()
        for (i, dot) in dots.enumerated() {
            guard let layer = dot.layer else { continue }
            layer.removeAnimation(forKey: "pulse")
            let anim = CABasicAnimation(keyPath: "opacity")
            anim.fromValue = Applied.Capture.loadingDotMinAlpha
            anim.toValue = 1.0
            anim.duration = period / 2
            anim.autoreverses = true
            anim.repeatCount = .infinity
            anim.beginTime = now + phase * Double(i)
            anim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            layer.add(anim, forKey: "pulse")
        }
    }

    private func stopAnimating() {
        guard animating else { return }
        animating = false
        for dot in dots {
            dot.layer?.removeAnimation(forKey: "pulse")
        }
    }
}
