import Foundation
import GRDB

// Must run before any event is appended; events have a device_id FK to this row.
nonisolated enum DeviceBootstrap {
    private static let deviceIdDefaultsKey = "OCS.deviceID"

    static func ensureLocalDevice(
        database: Database,
        ids: any IDs,
        clock: any Clock
    ) throws -> UUID {
        let defaults = UserDefaults.standard
        let deviceId: UUID
        let isFirstLaunch: Bool
        if let stored = defaults.string(forKey: deviceIdDefaultsKey),
           let parsed = UUID(uuidString: stored) {
            deviceId = parsed
            isFirstLaunch = false
        } else {
            deviceId = ids.next()
            isFirstLaunch = true
        }

        let now = clock.now().unixMillis
        let name = ProcessInfo.processInfo.hostName

        try database.queue.write { db in
            let exists = try Bool.fetchOne(
                db,
                sql: Queries.selectDevice,
                arguments: [deviceId.uuidString]
            ) ?? false

            if exists {
                try db.execute(
                    sql: Queries.updateDeviceLastSeen,
                    arguments: [now, deviceId.uuidString]
                )
            } else {
                try db.execute(
                    sql: Queries.insertDevice,
                    arguments: [deviceId.uuidString, name, now, now]
                )
            }
        }

        if isFirstLaunch {
            defaults.set(deviceId.uuidString, forKey: deviceIdDefaultsKey)
        }

        return deviceId
    }
}
