import Foundation

@MainActor
final class EntryMoveDispatcher {
    typealias Dispatch = @Sendable (_ entryId: UUID, _ toBin: Bin) async throws -> Void

    private let dispatch: Dispatch

    init(dispatch: @escaping Dispatch) {
        self.dispatch = dispatch
    }

    func send(entryId: UUID, toBin: Bin) {
        let dispatch = self.dispatch
        Task.detached {
            do {
                try await dispatch(entryId, toBin)
            } catch {
                NSLog("OCS: move failed: %@", String(describing: error))
            }
        }
    }
}
