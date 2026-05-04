import Foundation

@MainActor
final class CaptureHistoryCoordinator {
    private let loader: EntriesLoader
    private var state: CaptureHistoryState = .empty
    private var loading: Bool = false

    init(loader: EntriesLoader) {
        self.loader = loader
    }

    var isActive: Bool { state.isActive }

    func reset() {
        state = .empty
        loading = false
        loader.cancel()
    }

    func cancel() {
        loader.cancel()
        loading = false
    }

    func exitRecall(currentField: String) {
        guard state.isActive else { return }
        state = state.exitingRecall(currentField: currentField)
    }

    func stepForward() -> CaptureHistoryState? {
        let next = state.steppingForward()
        guard next != state else { return nil }
        state = next
        return next
    }

    // Returns the new state synchronously when items are already loaded; otherwise kicks off a fetch
    // and delivers the stepped state via onLoaded once the fetch returns.
    func stepBack(currentField: String, onLoaded: @MainActor @escaping (CaptureHistoryState) -> Void) -> CaptureHistoryState? {
        if !state.itemsLoaded {
            if !loading { load(currentField: currentField, onLoaded: onLoaded) }
            return nil
        }
        let next = state.steppingBack(currentField: currentField)
        guard next != state else { return nil }
        state = next
        return next
    }

    private func load(currentField: String, onLoaded: @MainActor @escaping (CaptureHistoryState) -> Void) {
        loading = true
        loader.loadFirst(
            scope: .active,
            onSpinnerReveal: {},
            onResult: { [weak self] outcome in
                guard let self else { return }
                self.loading = false
                guard case .loaded(let items) = outcome, !items.isEmpty else { return }
                let adopted = self.state.adopting(items)
                let next = adopted.steppingBack(currentField: currentField)
                self.state = next
                onLoaded(next)
            }
        )
    }
}
