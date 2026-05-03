import Foundation

nonisolated enum Queries {
    static let insertEntryEventCaptured = load("insert_entry_event_captured")
    static let projectEntryCaptured = load("project_entry_captured")

    static let selectEntriesRecent = load("select_entries_recent")
    static let selectEntriesRecentBefore = load("select_entries_recent_before")

    static let selectDevice = load("select_device")
    static let insertDevice = load("insert_device")
    static let updateDeviceLastSeen = load("update_device_last_seen")

    private static func load(_ name: String) -> String {
        guard let url = Bundle.main.url(forResource: name, withExtension: "sql") else {
            preconditionFailure("OCS: missing SQL resource \(name).sql in app bundle")
        }
        do {
            return try String(contentsOf: url, encoding: .utf8)
        } catch {
            preconditionFailure("OCS: failed to read SQL resource \(name).sql — \(error)")
        }
    }
}
