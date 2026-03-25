import Foundation
import SQLite

class SettingsStore: ObservableObject {

    static let shared = SettingsStore()

    @Published var lastFolderID: String?
    @Published var downloadPath: String?
    @Published var mountOnLaunch: Bool = true

    private var db: Connection?

    // Table
    private let settings = Table("settings")
    private let keyCol = Expression<String>("key")
    private let valueCol = Expression<String>("value")

    private init() {
        setupDatabase()
    }

    private func setupDatabase() {
        let fileManager = FileManager.default
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let nimbusDir = appSupport.appendingPathComponent("NIMBUS", isDirectory: true)

        do {
            try fileManager.createDirectory(at: nimbusDir, withIntermediateDirectories: true)
            let dbPath = nimbusDir.appendingPathComponent("settings.sqlite3")
            db = try Connection(dbPath.path)

            try db?.run(settings.create(ifNotExists: true) { t in
                t.column(keyCol, primaryKey: true)
                t.column(valueCol)
            })
        } catch {
            print("Database setup failed: \(error)")
        }
    }

    func loadSettings() {
        guard let db = db else { return }

        do {
            for row in try db.prepare(settings) {
                let key = row[keyCol]
                let value = row[valueCol]

                switch key {
                case "lastFolderID":
                    lastFolderID = value
                case "downloadPath":
                    downloadPath = value
                case "mountOnLaunch":
                    mountOnLaunch = value == "true"
                default:
                    break
                }
            }
        } catch {
            print("Failed to load settings: \(error)")
        }
    }

    func saveSetting(key: String, value: String) {
        guard let db = db else { return }

        do {
            try db.run(settings.insert(or: .replace,
                keyCol <- key,
                valueCol <- value
            ))
        } catch {
            print("Failed to save setting: \(error)")
        }
    }

    func setLastFolderID(_ id: String?) {
        lastFolderID = id
        if let id = id {
            saveSetting(key: "lastFolderID", value: id)
        }
    }

    func setDownloadPath(_ path: String?) {
        downloadPath = path
        if let path = path {
            saveSetting(key: "downloadPath", value: path)
        }
    }

    func setMountOnLaunch(_ enabled: Bool) {
        mountOnLaunch = enabled
        saveSetting(key: "mountOnLaunch", value: enabled ? "true" : "false")
    }
}
