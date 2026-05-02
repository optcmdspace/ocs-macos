import Foundation
import GRDB

nonisolated enum Migrations {
    static func register(in migrator: inout DatabaseMigrator) {
        for url in discover() {
            let identifier = url.deletingPathExtension().lastPathComponent
            migrator.registerMigration(identifier) { db in
                let sql = try String(contentsOf: url, encoding: .utf8)
                try db.execute(sql: sql)
            }
        }
    }

    // Distinguishes migrations from queries/*.sql since both share the flat resource bundle.
    private static func isMigrationFilename(_ name: String) -> Bool {
        guard name.count > 16 else { return false }
        let prefix = name.prefix(15)
        guard prefix.allSatisfy(\.isASCII), prefix.allSatisfy(\.isNumber) else { return false }
        return name[name.index(name.startIndex, offsetBy: 15)] == "_"
    }

    private static func discover() -> [URL] {
        guard let urls = Bundle.main.urls(forResourcesWithExtension: "sql", subdirectory: nil) else {
            fatalError("OCS: no .sql resources found in app bundle")
        }
        let migrations = urls.filter { isMigrationFilename($0.lastPathComponent) }
        guard !migrations.isEmpty else {
            fatalError("OCS: no migration .sql files found in app bundle")
        }
        return migrations.sorted { $0.lastPathComponent < $1.lastPathComponent }
    }
}
