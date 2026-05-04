import AppKit

@MainActor
enum CaptureSoundPreference {
    private static let key = "OCSCaptureSoundEnabled"

    static var isEnabled: Bool {
        UserDefaults.standard.bool(forKey: key)
    }

    static func setEnabled(_ on: Bool) {
        UserDefaults.standard.set(on, forKey: key)
    }

    static func playIfEnabled() {
        guard isEnabled else { return }
        NSSound(named: NSSound.Name("Bottle"))?.play()
    }
}
