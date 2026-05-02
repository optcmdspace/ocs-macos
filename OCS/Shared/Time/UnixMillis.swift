import Foundation

extension Date {
    nonisolated var unixMillis: Int64 {
        Int64((timeIntervalSince1970 * 1000).rounded())
    }
}
