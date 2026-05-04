import AppKit

enum CaptureNavDirection: Sendable {
    case down, up, pageDown, pageUp
}

enum CaptureIntent: Sendable {
    case dismiss
    case commit(keepOpen: Bool)
    case navigate(CaptureNavDirection)
    case autocompleteSuggestion
    case deleteSelected
    case consume
}

@MainActor
enum CaptureKeyRouter {
    static func intent(for selector: Selector) -> CaptureIntent? {
        switch selector {
        case #selector(NSResponder.cancelOperation(_:)):
            return .dismiss
        case #selector(NSResponder.insertNewline(_:)):
            let cmd = NSApp.currentEvent?.modifierFlags.contains(.command) ?? false
            return .commit(keepOpen: cmd)
        case #selector(NSResponder.insertLineBreak(_:)):
            return .commit(keepOpen: false)
        case #selector(NSResponder.moveDown(_:)):
            return .navigate(.down)
        case #selector(NSResponder.moveUp(_:)):
            return .navigate(.up)
        case #selector(NSResponder.scrollPageDown(_:)),
             #selector(NSResponder.pageDown(_:)):
            return .navigate(.pageDown)
        case #selector(NSResponder.scrollPageUp(_:)),
             #selector(NSResponder.pageUp(_:)):
            return .navigate(.pageUp)
        case #selector(NSResponder.insertTab(_:)):
            return .autocompleteSuggestion
        case #selector(NSResponder.insertBacktab(_:)):
            return .consume
        case #selector(NSResponder.deleteBackward(_:)):
            return .deleteSelected
        default:
            return nil
        }
    }
}
