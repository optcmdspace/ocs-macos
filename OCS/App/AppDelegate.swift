import AppKit
import KeyboardShortcuts

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

        let controller = CapturePanelController(
            dispatchCapture: composition.dispatchCapture,
            dispatchListRecent: composition.dispatchListRecent,
            dispatchMove: composition.dispatchMove
        )
        captureController = controller

        KeyboardShortcuts.onKeyDown(for: .toggleCapture) { [weak controller] in
            controller?.toggle()
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}
