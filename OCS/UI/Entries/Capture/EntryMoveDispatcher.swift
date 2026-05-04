import Foundation

@MainActor
final class EntryMoveDispatcher {
    typealias Dispatch = @Sendable (_ entryId: UUID, _ toBin: Bin) async throws -> Void

    private let dispatch: Dispatch
    private let preview: PreviewLoader

    init(dispatch: @escaping Dispatch, preview: PreviewLoader) {
        self.dispatch = dispatch
        self.preview = preview
    }

    func send(entryId: UUID, toBin: Bin) {
        let dispatch = self.dispatch
        let invalidatesCache = (toBin == .done || toBin == .trash)
        Task.detached { [weak preview] in
            do {
                try await dispatch(entryId, toBin)
                if invalidatesCache {
                    await MainActor.run { preview?.invalidateIfMatches(entryId) }
                }
            } catch {
                NSLog("OCS: move failed: %@", String(describing: error))
            }
        }
    }
}
