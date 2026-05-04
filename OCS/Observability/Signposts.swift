import Foundation
import os

// View intervals in Instruments → Points of Interest.
nonisolated enum Signposts {
    static let signposter = OSSignposter(subsystem: "space.optcmd.OCS", category: "capture-hot-path")
}
