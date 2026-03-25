import Foundation
import AppKit

// MARK: - Download Item

struct DownloadItem: Identifiable {
    let id: UUID
    let file: DriveFile
    var progress: Double
    var status: DownloadStatus
    var localURL: URL?
    var error: String?

    init(file: DriveFile) {
        self.id = UUID()
        self.file = file
        self.progress = 0
        self.status = .pending
    }

    enum DownloadStatus {
        case pending, downloading, completed, failed, cancelled
    }
}

// MARK: - Download Manager

@MainActor
final class DownloadManager: ObservableObject {
    static let shared = DownloadManager()

    @Published var queue: [DownloadItem] = []
    @Published var activeDownloads: [UUID: Double] = [:]  // id -> progress

    private let driveService = GoogleDriveService.shared

    private init() {}

    func download(_ file: DriveFile) {
        let item = DownloadItem(file: file)
        queue.append(item)
        processQueue()
    }

    func downloadBatch(_ files: [DriveFile]) {
        for file in files {
            download(file)
        }
    }

    func cancelDownload(_ id: UUID) {
        if let idx = queue.firstIndex(where: { $0.id == id }) {
            queue.remove(at: idx)
        }
        activeDownloads.removeValue(forKey: id)
    }

    func cancelAll() {
        queue.removeAll()
        activeDownloads.removeAll()
    }

    private func processQueue() {
        let activeCount = queue.filter { $0.status == .downloading }.count
        guard activeCount < 3 else { return }

        if let idx = queue.firstIndex(where: { $0.status == .pending }) {
            queue[idx].status = .downloading
            let item = queue[idx]
            activeDownloads[item.id] = 0

            Task {
                do {
                    let localURL = try await driveService.downloadToLocal(item.file)
                    await MainActor.run {
                        if let i = self.queue.firstIndex(where: { $0.id == item.id }) {
                            self.queue[i].status = .completed
                            self.queue[i].localURL = localURL
                            self.queue[i].progress = 1.0
                        }
                        self.activeDownloads.removeValue(forKey: item.id)
                        self.processQueue()
                    }
                } catch {
                    await MainActor.run {
                        if let i = self.queue.firstIndex(where: { $0.id == item.id }) {
                            self.queue[i].status = .failed
                            self.queue[i].error = error.localizedDescription
                        }
                        self.activeDownloads.removeValue(forKey: item.id)
                        self.processQueue()
                    }
                }
            }
        }
    }
}

// MARK: - Search

@MainActor
final class FileSearchService: ObservableObject {
    @Published var query: String = ""
    @Published var results: [DriveFile] = []
    @Published var isSearching: Bool = false

    private let driveService = GoogleDriveService.shared
    private var searchTask: Task<Void, Never>?

    func search() {
        searchTask?.cancel()

        guard !query.isEmpty else {
            results = []
            return
        }

        isSearching = true

        searchTask = Task {
            // Google Drive API doesn't have a local search, so we search the loaded files
            try? await Task.sleep(nanoseconds: 300_000_000)  // 300ms debounce

            guard !Task.isCancelled else { return }

            let lowercased = query.lowercased()
            let filtered = driveService.files.filter { file in
                file.name.lowercased().contains(lowercased)
            }

            await MainActor.run {
                self.results = filtered
                self.isSearching = false
            }
        }
    }
}

// MARK: - Favorites Store

@MainActor
final class FavoritesStore: ObservableObject {
    static let shared = FavoritesStore()

    @Published var favorites: [DriveFile] = []

    private let key = "nimbus_favorites"

    private init() {
        loadFavorites()
    }

    func addFavorite(_ file: DriveFile) {
        guard !isFavorite(file.id) else { return }
        var updated = file
        favorites.append(updated)
        saveFavorites()
    }

    func removeFavorite(_ fileID: String) {
        favorites.removeAll { $0.id == fileID }
        saveFavorites()
    }

    func isFavorite(_ fileID: String) -> Bool {
        favorites.contains { $0.id == fileID }
    }

    private func saveFavorites() {
        guard let encoded = try? JSONEncoder().encode(favorites) else { return }
        UserDefaults.standard.set(encoded, forKey: key)
    }

    private func loadFavorites() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([DriveFile].self, from: data) else {
            return
        }
        favorites = decoded
    }
}

// MARK: - Recent Files Store

@MainActor
final class RecentFilesStore: ObservableObject {
    static let shared = RecentFilesStore()

    @Published var recentFiles: [DriveFile] = []

    private let key = "nimbus_recent_files"
    private let maxRecent = 20

    private init() {
        loadRecent()
    }

    func addRecent(_ file: DriveFile) {
        // Remove if already exists
        recentFiles.removeAll { $0.id == file.id }
        // Add to front
        recentFiles.insert(file, at: 0)
        // Trim to max
        if recentFiles.count > maxRecent {
            recentFiles = Array(recentFiles.prefix(maxRecent))
        }
        saveRecent()
    }

    private func saveRecent() {
        guard let encoded = try? JSONEncoder().encode(recentFiles) else { return }
        UserDefaults.standard.set(encoded, forKey: key)
    }

    private func loadRecent() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([DriveFile].self, from: data) else {
            return
        }
        recentFiles = decoded
    }
}
