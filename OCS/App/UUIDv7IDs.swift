import Foundation
import os

// Monotonic UUIDv7 (RFC 9562 §6.2 method 1): 12-bit counter in rand_a keeps within-millisecond ids byte-ordered, so the fold order matches emission order on every peer.
nonisolated final class UUIDv7IDs: IDs {
    private let clock: any Clock
    private let lock = OSAllocatedUnfairLock(initialState: State())

    private struct State {
        var lastMs: UInt64 = 0
        var counter: UInt16 = 0
    }

    init(clock: any Clock) {
        self.clock = clock
    }

    func next() -> UUID {
        let nowMs = UInt64(clock.now().unixMillis)
        return lock.withLock { state -> UUID in
            var ms = nowMs
            var counter: UInt16
            if nowMs > state.lastMs {
                counter = UInt16.random(in: 0..<0x800)
            } else {
                ms = state.lastMs
                counter = state.counter &+ 1
                if counter >= 0x1000 {
                    ms = state.lastMs &+ 1
                    counter = UInt16.random(in: 0..<0x800)
                }
            }
            state.lastMs = ms
            state.counter = counter

            var rng = SystemRandomNumberGenerator()
            let r1 = UInt64.random(in: UInt64.min...UInt64.max, using: &rng)
            let r2 = UInt64.random(in: UInt64.min...UInt64.max, using: &rng)

            let b0 = UInt8((ms >> 40) & 0xFF)
            let b1 = UInt8((ms >> 32) & 0xFF)
            let b2 = UInt8((ms >> 24) & 0xFF)
            let b3 = UInt8((ms >> 16) & 0xFF)
            let b4 = UInt8((ms >> 8) & 0xFF)
            let b5 = UInt8(ms & 0xFF)
            let b6 = 0x70 | UInt8((counter >> 8) & 0x0F)
            let b7 = UInt8(counter & 0xFF)
            let b8 = 0x80 | UInt8((r1 >> 56) & 0x3F)
            let b9 = UInt8((r1 >> 48) & 0xFF)
            let b10 = UInt8((r1 >> 40) & 0xFF)
            let b11 = UInt8((r1 >> 32) & 0xFF)
            let b12 = UInt8((r2 >> 56) & 0xFF)
            let b13 = UInt8((r2 >> 48) & 0xFF)
            let b14 = UInt8((r2 >> 40) & 0xFF)
            let b15 = UInt8((r2 >> 32) & 0xFF)

            return UUID(uuid: (b0, b1, b2, b3, b4, b5, b6, b7,
                               b8, b9, b10, b11, b12, b13, b14, b15))
        }
    }
}
