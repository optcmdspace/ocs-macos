import Foundation

@MainActor
final class StatsLoader {
    typealias Dispatch = @Sendable (_ todayStartMillis: Int64, _ yesterdayStartMillis: Int64, _ staleCutoffMillis: Int64) async throws -> EntryStats

    private let dispatch: Dispatch
    private var task: Task<Void, Never>?
    private(set) var stats: EntryStats?

    init(dispatch: @escaping Dispatch) {
        self.dispatch = dispatch
    }

    func cancel() {
        task?.cancel()
        task = nil
    }

    func reset() {
        cancel()
        stats = nil
    }

    // The user's local calendar stays in the UI layer; the handler takes absolute boundaries.
    func load(now: Date, onResult: @escaping @MainActor (EntryStats) -> Void) {
        cancel()
        let cal = Calendar.current
        let todayStart = cal.startOfDay(for: now)
        guard let yesterdayStart = cal.date(byAdding: .day, value: -1, to: todayStart),
              let staleCutoff = cal.date(byAdding: .day, value: -AgingThresholds.entryStaleAfterDays, to: now)
        else { return }
        let dispatch = self.dispatch
        task = Task { [weak self] in
            do {
                let result = try await dispatch(
                    todayStart.unixMillis,
                    yesterdayStart.unixMillis,
                    staleCutoff.unixMillis
                )
                if Task.isCancelled { return }
                self?.stats = result
                onResult(result)
            } catch {
                NSLog("OCS: stats query failed: %@", String(describing: error))
            }
        }
    }
}
