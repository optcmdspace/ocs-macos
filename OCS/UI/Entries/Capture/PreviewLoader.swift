import Foundation

@MainActor
final class PreviewLoader {
    typealias Dispatch = @Sendable (_ limit: Int, _ scope: ListRecentEntriesQuery.Scope, _ before: ListRecentEntriesQuery.Cursor?) async throws -> [EntryListItem]

    private let dispatch: Dispatch
    private var task: Task<Void, Never>?
    private(set) var cached: EntryListItem?

    init(dispatch: @escaping Dispatch) {
        self.dispatch = dispatch
    }

    func adopt(_ item: EntryListItem) {
        cached = item
    }

    func invalidateIfMatches(_ id: UUID) {
        if cached?.id == id { cached = nil }
    }

    func cancel() {
        task?.cancel()
        task = nil
    }

    // Deferred a frame so a fast typist's capture write doesn't contend with this read.
    func fetch(onResult: @escaping @MainActor (EntryListItem?) -> Void) {
        cancel()
        let dispatch = self.dispatch
        task = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(80))
            if Task.isCancelled { return }
            do {
                let items = try await dispatch(1, .active, nil)
                if Task.isCancelled { return }
                self?.cached = items.first
                onResult(items.first)
            } catch {
                NSLog("OCS: preview fetch failed: %@", String(describing: error))
                if !Task.isCancelled { onResult(nil) }
            }
        }
    }
}
