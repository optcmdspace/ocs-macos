import Foundation

nonisolated enum EntriesFilter: Sendable, Equatable {
    case none
    // The recent list with past-due entries collapsed out of the load (the default). Carries the
    // start-of-today boundary that defines "overdue".
    case recentCollapsed(overdueBeforeMillis: Int64)
    case find(text: String?, tags: [TagName])
    // The agenda: entries with a due date, grouped by horizon. Rendered by CaptureResultsRenderer.
    case due
}
