//
//  Shortcuts.swift
//  OCS
//

import AppKit
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let toggleCapture = Self(
        "toggleCapture",
        default: .init(.space, modifiers: [.option, .command])
    )
}
