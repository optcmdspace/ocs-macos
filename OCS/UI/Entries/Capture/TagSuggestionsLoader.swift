import Foundation

@MainActor
final class TagSuggestionsLoader {
    private let dispatch: DispatchTagSuggestions
    private let limit: Int
    private var task: Task<Void, Never>?

    init(dispatch: @escaping DispatchTagSuggestions, limit: Int = 8) {
        self.dispatch = dispatch
        self.limit = limit
    }

    func cancel() {
        task?.cancel()
        task = nil
    }

    func load(prefix: String, onResult: @escaping @MainActor ([TagSuggestion]) -> Void) {
        cancel()
        let dispatch = self.dispatch
        let limit = self.limit
        task = Task {
            do {
                let items = try await dispatch(prefix, limit)
                if Task.isCancelled { return }
                onResult(items)
            } catch {
                NSLog("OCS: tag autocomplete failed: %@", String(describing: error))
            }
        }
    }
}
