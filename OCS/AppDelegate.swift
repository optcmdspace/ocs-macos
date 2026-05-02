//
//  AppDelegate.swift
//  OCS
//

import AppKit
import KeyboardShortcuts

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var captureController: CapturePanelController?
    private var database: Database?

    func applicationDidFinishLaunching(_ notification: Notification) {
        do {
            database = try Database()
        } catch {
            fatalError("OCS: failed to open database — \(error)")
        }

        let controller = CapturePanelController()
        captureController = controller

        KeyboardShortcuts.onKeyDown(for: .toggleCapture) { [weak controller] in
            controller?.toggle()
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}
