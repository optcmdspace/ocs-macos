import Foundation

@MainActor
final class EntriesLoader {
    typealias Dispatch = @Sendable (
        _ limit: Int,
        _ scope: ListRecentEntriesQuery.Scope,
        _ filter: EntriesFilter,
        _ before: ListRecentEntriesQuery.Cursor?
    ) async throws -> [EntryListItem]

    enum Outcome {
        case loaded([EntryListItem])
        case failed
    }

    private let dispatch: Dispatch
    private let pageSize: Int
    private let revealAfter: Duration
    private var task: Task<Void, Never>?
    private var revealTask: Task<Void, Never>?

    init(dispatch: @escaping Dispatch, pageSize: Int, revealAfter: Duration = .milliseconds(100)) {
        self.dispatch = dispatch
        self.pageSize = pageSize
        self.revealAfter = revealAfter
    }

    func cancel() {
        task?.cancel()
        revealTask?.cancel()
        task = nil
        revealTask = nil
    }

    // First page; the spinner reveal fires only if the fetch is still in flight after the threshold,
    // so a fast query never flashes a spinner.
    func loadFirst(
        scope: ListRecentEntriesQuery.Scope,
        filter: EntriesFilter = .none,
        onSpinnerReveal: @escaping @MainActor () -> Void,
        onResult: @escaping @MainActor (Outcome) -> Void
    ) {
        cancel()
        let dispatch = self.dispatch
        let pageSize = self.pageSize
        let revealAfter = self.revealAfter
        revealTask = Task { @MainActor in
            try? await Task.sleep(for: revealAfter)
            if Task.isCancelled { return }
            onSpinnerReveal()
        }
        task = Task { [weak self] in
            do {
                let items = try await dispatch(pageSize, scope, filter, nil)
                if Task.isCancelled { return }
                self?.revealTask?.cancel()
                self?.revealTask = nil
                onResult(.loaded(items))
            } catch {
                NSLog("OCS: list query failed: %@", String(describing: error))
                self?.revealTask?.cancel()
                self?.revealTask = nil
                if Task.isCancelled { return }
                onResult(.failed)
            }
        }
    }

    func loadMore(
        scope: ListRecentEntriesQuery.Scope,
        filter: EntriesFilter = .none,
        before: ListRecentEntriesQuery.Cursor,
        onResult: @escaping @MainActor (Outcome) -> Void
    ) {
        task?.cancel()
        let dispatch = self.dispatch
        let pageSize = self.pageSize
        task = Task {
            do {
                let items = try await dispatch(pageSize, scope, filter, before)
                if Task.isCancelled { return }
                onResult(.loaded(items))
            } catch {
                NSLog("OCS: list page query failed: %@", String(describing: error))
                if Task.isCancelled { return }
                onResult(.failed)
            }
        }
    }
}
