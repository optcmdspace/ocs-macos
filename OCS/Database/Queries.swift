import Foundation

nonisolated enum Queries {
    static let insertEntryEventCaptured = load("insert_entry_event_captured")
    static let insertEntryEventMoved = load("insert_entry_event_moved")
    static let insertEntryEventTagged = load("insert_entry_event_tagged")
    static let insertEntryEventUntagged = load("insert_entry_event_untagged")
    static let insertEntryEventScheduled = load("insert_entry_event_scheduled")
    static let insertTagEventCreated = load("insert_tag_event_created")
    static let insertTagEventArchived = load("insert_tag_event_archived")
    static let insertTagEventUnarchived = load("insert_tag_event_unarchived")
    static let projectEntryCaptured = load("project_entry_captured")
    static let projectEntryMoved = load("project_entry_moved")
    static let projectEntryScheduled = load("project_entry_scheduled")
    static let projectEntryTagged = load("project_entry_tagged")
    static let projectEntryTaggedTouch = load("project_entry_tagged_touch")
    static let projectEntryUntagged = load("project_entry_untagged")
    static let projectTagCreated = load("project_tag_created")
    static let projectTagDemote = load("project_tag_demote")
    static let projectTagFlattenChains = load("project_tag_flatten_chains")
    static let projectTagMigrateEntryTags = load("project_tag_migrate_entry_tags")
    static let projectTagClearEntryTags = load("project_tag_clear_entry_tags")
    static let projectTagArchived = load("project_tag_archived")
    static let projectTagUnarchived = load("project_tag_unarchived")

    static let selectEntriesRecent = load("select_entries_recent")
    static let selectEntriesRecentBefore = load("select_entries_recent_before")
    static let selectEntriesFind = load("select_entries_find")
    static let selectEntriesFindBefore = load("select_entries_find_before")
    static let selectEntriesDue = load("select_entries_due")
    static let selectEntriesLatest = load("select_entries_latest")
    static let selectEntryById = load("select_entry_by_id")
    static let selectEntryStats = load("select_entry_stats")
    static let selectTagActiveByName = load("select_tag_active_by_name")
    static let selectTagsActiveByNames = load("select_tags_active_by_names")
    static let selectTagCanonical = load("select_tag_canonical")
    static let selectTagSuggestions = load("select_tag_suggestions")
    static let selectTagsManage = load("select_tags_manage")

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
            preconditionFailure("OCS: failed to read SQL resource \(name).sql: \(error)")
        }
    }
}
