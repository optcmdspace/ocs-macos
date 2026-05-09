import AppKit

@MainActor
enum TagPalette {
    private struct Hue: Sendable {
        let hue: CGFloat
        let saturation: CGFloat
        let brightness: CGFloat
    }

    private static let hues: [Hue] = [
        Hue(hue: 0.50, saturation: 0.55, brightness: 0.95),
        Hue(hue: 0.58, saturation: 0.55, brightness: 0.95),
        Hue(hue: 0.70, saturation: 0.45, brightness: 0.95),
        Hue(hue: 0.80, saturation: 0.45, brightness: 0.95),
        Hue(hue: 0.92, saturation: 0.50, brightness: 0.95),
        Hue(hue: 0.03, saturation: 0.55, brightness: 0.95),
        Hue(hue: 0.10, saturation: 0.55, brightness: 0.95),
        Hue(hue: 0.25, saturation: 0.50, brightness: 0.85),
        Hue(hue: 0.42, saturation: 0.45, brightness: 0.85),
    ]

    static func foreground(for name: String, selected: Bool) -> NSColor {
        let h = pick(name)
        return NSColor(hue: h.hue, saturation: h.saturation, brightness: h.brightness, alpha: selected ? 1.0 : 0.6)
    }

    static func background(for name: String, selected: Bool) -> NSColor {
        let h = pick(name)
        return NSColor(hue: h.hue, saturation: h.saturation, brightness: h.brightness, alpha: selected ? 0.22 : 0.12)
    }

    private static func pick(_ name: String) -> Hue {
        let idx = stableHash(name) % hues.count
        return hues[idx]
    }

    // FNV-1a. Swift's hashValue is process-randomized, so colors would shift across launches.
    private static func stableHash(_ s: String) -> Int {
        var h: UInt32 = 0x811C9DC5
        for byte in s.utf8 {
            h ^= UInt32(byte)
            h &*= 0x01000193
        }
        return Int(h)
    }
}
