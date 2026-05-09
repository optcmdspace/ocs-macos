import Foundation

@MainActor
final class LiveFindCoordinator {
    typealias Dispatch = EntriesLoader.Dispatch

    private let pageSize: Int
    private let windowSize: Int
    private let getPage: () -> CapturePageMode
    private let setPage: (CapturePageMode) -> Void
    private let onHeightChange: () -> Void
    private let loader: EntriesLoader
    private var debounce: Task<Void, Never>?

    init(
        dispatch: @escaping Dispatch,
        pageSize: Int,
        windowSize: Int,
        getPage: @escaping () -> CapturePageMode,
        setPage: @escaping (CapturePageMode) -> Void,
        onHeightChange: @escaping () -> Void
    ) {
        self.pageSize = pageSize
        self.windowSize = windowSize
        self.getPage = getPage
        self.setPage = setPage
        self.onHeightChange = onHeightChange
        self.loader = EntriesLoader(dispatch: dispatch, pageSize: pageSize)
    }

    static func isFindContext(_ raw: String) -> Bool {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return trimmed == "/find" || trimmed.hasPrefix("/find ") || trimmed.hasPrefix("/find\t")
    }

    func cancel() {
        debounce?.cancel()
        debounce = nil
        loader.cancel()
    }

    // True when the field is in /find context; the caller should skip its slash-suggestion fallback.
    func handleFieldChange(raw: String) -> Bool {
        guard Self.isFindContext(raw) else { return false }
        kickoff(raw: raw)
        return true
    }

    // Re-fires the live find after a programmatic field edit (tag accept, slash pick) since
    // those don't trigger NSText.didChange and so handleFieldChange isn't called on its own.
    func kickoff(raw: String) {
        guard case .find(let text, let tags, let scope) = SlashCommand.parse(raw) else { return }
        let filter: EntriesFilter = .find(text: text, tags: tags)

        if case .findResults = getPage() {
            // Keep the current items mounted across keystrokes so the panel doesn't blink.
        } else {
            let initial = EntriesListPageState.empty(windowSize: windowSize, scope: scope, filter: filter).startingLoad()
            setPage(.findResults(initial))
            onHeightChange()
        }

        debounce?.cancel()
        debounce = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(120))
            if Task.isCancelled { return }
            self?.run(scope: scope, filter: filter)
        }
    }

    func loadMore(from state: EntriesListPageState) {
        guard let cursor = state.nextCursor else { return }
        setPage(.findResults(state.startingLoad()))
        let pageSize = self.pageSize
        loader.loadMore(scope: state.scope, filter: state.filter, before: cursor) { [weak self] outcome in
            guard let self, case .findResults(let e) = self.getPage() else { return }
            switch outcome {
            case .loaded(let items):
                self.setPage(.findResults(e.appending(items, requestedLimit: pageSize)))
            case .failed:
                self.setPage(.findResults(e.failedLoad()))
            }
            self.onHeightChange()
        }
    }

    private func run(scope: ListRecentEntriesQuery.Scope, filter: EntriesFilter) {
        let pageSize = self.pageSize
        let windowSize = self.windowSize
        loader.loadFirst(
            scope: scope,
            filter: filter,
            onSpinnerReveal: { [weak self] in
                guard let self else { return }
                if case .findResults(let e) = self.getPage(), e.list.isEmpty, !e.loadingVisible {
                    self.setPage(.findResults(e.revealingLoad()))
                    self.onHeightChange()
                }
            },
            onResult: { [weak self] outcome in
                guard let self else { return }
                switch outcome {
                case .loaded(let items):
                    let next = EntriesListPageState.empty(windowSize: windowSize, scope: scope, filter: filter)
                        .appending(items, requestedLimit: pageSize)
                    self.setPage(.findResults(next))
                case .failed:
                    if case .findResults(let e) = self.getPage() {
                        self.setPage(.findResults(e.failedLoad()))
                    }
                }
                self.onHeightChange()
            }
        )
    }
}
