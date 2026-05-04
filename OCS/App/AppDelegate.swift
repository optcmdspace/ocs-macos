import AppKit
import KeyboardShortcuts
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
            dispatchEntryStats: composition.dispatchEntryStats
        )
        captureController = controller

        KeyboardShortcuts.onKeyDown(for: .toggleCapture) { [weak controller] in
            let interval = Signposts.signposter.beginInterval("hotkey-toggle")
            controller?.toggle()
            Signposts.signposter.endInterval("hotkey-toggle", interval)
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}
