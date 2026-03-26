import Foundation

class SettingsStore: ObservableObject {

    static let shared = SettingsStore()

    @Published var lastFolderID: String?
    @Published var downloadPath: String?
    @Published var mountOnLaunch: Bool = true

    private var values: [String: String] = [:]

    private init() {
        loadSettings()
    }

    private var fileURL: URL {
        let fileManager = FileManager.default
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let nimbusDir = appSupport.appendingPathComponent("NIMBUS", isDirectory: true)
        try? fileManager.createDirectory(at: nimbusDir, withIntermediateDirectories: true)
        return nimbusDir.appendingPathComponent("settings.json")
    }

    func loadSettings() {
        if let data = try? Data(contentsOf: fileURL),
           let decoded = try? JSONDecoder().decode([String: String].self, from: data) {
            values = decoded
        }

        lastFolderID = values["lastFolderID"]
        downloadPath = values["downloadPath"]
        mountOnLaunch = values["mountOnLaunch"] != "false"
    }

    func saveSetting(key: String, value: String) {
        values[key] = value
        persist()
    }

    func setLastFolderID(_ id: String?) {
        lastFolderID = id
        if let id {
            values["lastFolderID"] = id
        } else {
            values.removeValue(forKey: "lastFolderID")
        }
        persist()
    }

    func setDownloadPath(_ path: String?) {
        downloadPath = path
        if let path {
            values["downloadPath"] = path
        } else {
            values.removeValue(forKey: "downloadPath")
        }
        persist()
    }

    func setMountOnLaunch(_ enabled: Bool) {
        mountOnLaunch = enabled
        values["mountOnLaunch"] = enabled ? "true" : "false"
        persist()
    }

    private func persist() {
        do {
            let data = try JSONEncoder().encode(values)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("Failed to persist settings: \(error)")
        }
    }
}
