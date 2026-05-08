import Foundation

@MainActor
enum CaptureDraftStore {
    private static let key = "OCSCaptureDraft"

    static var text: String {
        UserDefaults.standard.string(forKey: key) ?? ""
    }

    static func save(_ text: String) {
        if text.isEmpty {
            UserDefaults.standard.removeObject(forKey: key)
        } else {
            UserDefaults.standard.set(text, forKey: key)
        }
    }
}
