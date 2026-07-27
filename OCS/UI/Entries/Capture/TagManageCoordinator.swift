import Foundation

@MainActor
final class TagManageCoordinator {
    private static let limit = 200

    private let dispatch: DispatchListTags
    private let windowSize: Int
    private let getPage: () -> CapturePageMode
    private let setPage: (CapturePageMode) -> Void
    private let onHeightChange: () -> Void
    private var debounce: Task<Void, Never>?

    init(
        dispatch: @escaping DispatchListTags,
        windowSize: Int,
        getPage: @escaping () -> CapturePageMode,
        setPage: @escaping (CapturePageMode) -> Void,
        onHeightChange: @escaping () -> Void
    ) {
        self.dispatch = dispatch
        self.windowSize = windowSize
        self.getPage = getPage
        self.setPage = setPage
        self.onHeightChange = onHeightChange
    }

    static func isTagsContext(_ raw: String) -> Bool {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return trimmed == "/tags" || trimmed.hasPrefix("/tags ") || trimmed.hasPrefix("/tags\t")
    }

    func cancel() {
        debounce?.cancel()
        debounce = nil
    }

    // True when the field is in /tags context; the caller should skip its other fallbacks.
    func handleFieldChange(raw: String) -> Bool {
        guard Self.isTagsContext(raw) else { return false }
        kickoff(raw: raw)
        return true
    }

    func kickoff(raw: String) {
        guard case .manageTags(let query) = SlashCommand.parse(raw) else { return }
        let q = query ?? ""
        if case .tags(let existing) = getPage() {
            // Keep items mounted across keystrokes so the list doesn't blink.
            setPage(.tags(existing.withQuery(q).startingLoad()))
        } else {
            setPage(.tags(TagManageState.empty(windowSize: windowSize, query: q).startingLoad()))
            onHeightChange()
        }
        run(query: q)
    }

    private func run(query: String) {
        debounce?.cancel()
        let dispatch = self.dispatch
        debounce = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(120))
            if Task.isCancelled { return }
            guard let self else { return }
            do {
                let items = try await dispatch(query, Self.limit)
                if Task.isCancelled { return }
                guard case .tags(let state) = self.getPage(), state.query == query else { return }
                self.setPage(.tags(state.loaded(items)))
            } catch {
                if case .tags(let state) = self.getPage() {
                    self.setPage(.tags(state.failedLoad()))
                }
            }
            self.onHeightChange()
        }
    }
}
