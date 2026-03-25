import Foundation

@MainActor
final class NimbusSyncManager: ObservableObject {
    static let shared = NimbusSyncManager()

    @Published var syncStatus: SyncStatus = .idle
    @Published var lastSynced: Date?

    enum SyncStatus: Equatable {
        case idle
        case syncing
        case synced
        case offline
        case error(String)
    }

    private let store = NSUbiquitousKeyValueStore.default
    private var observers: [NSObjectProtocol] = []

    private init() {
        setupObservers()
    }

    private func setupObservers() {
        let notification = NSUbiquitousKeyValueStore.didChangeExternallyNotification
        let observer = NotificationCenter.default.addObserver(
            forName: notification,
            object: store,
            queue: .main
        ) { [weak self] _ in
            self?.handleExternalChange()
        }
        observers.append(observer)
    }

    // MARK: - Sync Data

    struct SyncPayload: Codable {
        var recentFiles: [DriveFile]
        var favorites: [String]
        var settings: NimbusSettings

        struct NimbusSettings: Codable {
            var sortOrder: String
            var showHidden: Bool
            var autoRefresh: Bool
        }
    }

    func sync() {
        guard isICloudAvailable else {
            syncStatus = .offline
            return
        }

        syncStatus = .syncing

        do {
            let payload = buildPayload()
            let data = try JSONEncoder().encode(payload)
            store.set(data, forKey: "nimbus.sync.data")
            store.synchronize()

            syncStatus = .synced
            lastSynced = Date()
        } catch {
            syncStatus = .error(error.localizedDescription)
        }
    }

    func pullFromCloud() {
        guard isICloudAvailable else { return }

        guard let data = store.data(forKey: "nimbus.sync.data"),
              let payload = try? JSONDecoder().decode(SyncPayload.self, from: data) else {
            return
        }

        applyPayload(payload)
    }

    private func buildPayload() -> SyncPayload {
        let settings = SyncPayload.NimbusSettings(
            sortOrder: UserDefaults.standard.string(forKey: "nimbus_sortOrder") ?? "name",
            showHidden: UserDefaults.standard.bool(forKey: "nimbus_showHidden"),
            autoRefresh: UserDefaults.standard.bool(forKey: "nimbus_autoRefresh")
        )

        return SyncPayload(
            recentFiles: NimbusState.shared.recentFiles,
            favorites: NimbusState.shared.favorites,
            settings: settings
        )
    }

    private func applyPayload(_ payload: SyncPayload) {
        NimbusState.shared.recentFiles = payload.recentFiles
        NimbusState.shared.favorites = payload.favorites

        UserDefaults.standard.set(payload.settings.sortOrder, forKey: "nimbus_sortOrder")
        UserDefaults.standard.set(payload.settings.showHidden, forKey: "nimbus_showHidden")
        UserDefaults.standard.set(payload.settings.autoRefresh, forKey: "nimbus_autoRefresh")
    }

    private func handleExternalChange() {
        pullFromCloud()
        syncStatus = .synced
        lastSynced = Date()
    }

    var isICloudAvailable: Bool {
        FileManager.default.ubiquityIdentityToken != nil
    }

    func syncNow() {
        sync()
    }

    deinit {
        observers.forEach { NotificationCenter.default.removeObserver($0) }
    }
}
