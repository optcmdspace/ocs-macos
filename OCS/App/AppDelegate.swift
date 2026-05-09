import AppKit
import KeyboardShortcuts
import ServiceManagement
import os

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var composition: Composition?
    private var captureController: CapturePanelController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let composition: Composition
        do {
            composition = try Composition()
        } catch {
            fatalError("OCS: bootstrap failed — \(error)")
        }
        self.composition = composition

        #if DEBUG
        Task { await DevFixtures.seedIfNeeded(seed: composition.dispatchSeedCapture) }
        #endif

        let controller = CapturePanelController(
            dispatchCapture: composition.dispatchCapture,
            dispatchListRecent: composition.dispatchListRecent,
            dispatchMove: composition.dispatchMove,
            dispatchEntryStats: composition.dispatchEntryStats,
            dispatchTagSuggestions: composition.dispatchTagSuggestions,
            dispatchSetEntryTags: composition.dispatchSetEntryTags
        )
        captureController = controller

        KeyboardShortcuts.onKeyDown(for: .toggleCapture) { [weak controller] in
            let interval = Signposts.signposter.beginInterval("hotkey-toggle")
            controller?.toggle()
            Signposts.signposter.endInterval("hotkey-toggle", interval)
        }

        registerAsLoginItemIfNeeded()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    private func registerAsLoginItemIfNeeded() {
        let key = "OCSHasRegisteredAsLoginItem"
        guard !UserDefaults.standard.bool(forKey: key) else { return }
        UserDefaults.standard.set(true, forKey: key)
        try? SMAppService.mainApp.register()
    }
}
