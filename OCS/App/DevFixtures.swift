#if DEBUG
import Foundation

nonisolated enum DevFixtures {
    private static let seededKey = "OCSDevFixturesSeeded"

    static func seedIfNeeded(
        seed: @Sendable (_ text: String, _ at: Date) async -> Void,
        now: Date = Date()
    ) async {
        guard !UserDefaults.standard.bool(forKey: seededKey) else { return }
        let day: TimeInterval = 86_400
        let fixtures: [(String, Date)] = [
            ("seed: 1 day old", now.addingTimeInterval(-1 * day)),
            ("seed: 8 days old", now.addingTimeInterval(-8 * day)),
            ("seed: 31 days old", now.addingTimeInterval(-31 * day)),
        ]
        for (text, at) in fixtures {
            await seed(text, at)
        }
        UserDefaults.standard.set(true, forKey: seededKey)
    }
}
#endif
