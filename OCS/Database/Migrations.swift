//
//  Migrations.swift
//  OCS
//

import Foundation
import GRDB

enum Migrations {
    static func register(in migrator: inout DatabaseMigrator) {
        for url in discover() {
            let identifier = url.deletingPathExtension().lastPathComponent
            migrator.registerMigration(identifier) { db in
                let sql = try String(contentsOf: url, encoding: .utf8)
                try db.execute(sql: sql)
            }
        }
    }

    private static func discover() -> [URL] {
        guard let urls = Bundle.main.urls(forResourcesWithExtension: "sql", subdirectory: nil),
              !urls.isEmpty
        else {
            fatalError("OCS: no migration .sql files found in app bundle")
        }
        return urls.sorted { $0.lastPathComponent < $1.lastPathComponent }
    }
}
