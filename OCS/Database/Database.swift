//
//  Database.swift
//  OCS
//

import Foundation
import GRDB

final class Database: Sendable {
    let queue: DatabaseQueue

    init() throws {
        let url = try Self.databaseURL()
        let queue = try DatabaseQueue(path: url.path)
        try Self.migrate(queue)
        self.queue = queue
    }

    private static func databaseURL() throws -> URL {
        let fm = FileManager.default
        let support = try fm.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let dir = support.appendingPathComponent("OCS", isDirectory: true)
        try fm.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("ocs.sqlite")
    }

    private static func migrate(_ queue: DatabaseQueue) throws {
        var migrator = DatabaseMigrator()
        Migrations.register(in: &migrator)
        try migrator.migrate(queue)
    }
}
