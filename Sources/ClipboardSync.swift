import Foundation

struct ClipboardSyncItem: Identifiable, Codable {
    let id: UUID
    let content: String
    let type: String
    let timestamp: Date
    let deviceId: String
}

final class ClipboardSyncManager {
    static let shared = ClipboardSyncManager()

    private let syncKey = "clipboardSync"
    private let deviceId: String

    private init() {
        deviceId = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
    }

    func syncItem(_ content: String, type: String) {
        let item = ClipboardSyncItem(
            id: UUID(),
            content: content,
            type: type,
            timestamp: Date(),
            deviceId: deviceId
        )

        var items = fetchItems()
        items.append(item)

        if items.count > 100 {
            items = Array(items.suffix(100))
        }

        saveItems(items)
    }

    func fetchItems() -> [ClipboardSyncItem] {
        guard let data = UserDefaults.standard.data(forKey: syncKey) else { return [] }
        do {
            return try JSONDecoder().decode([ClipboardSyncItem].self, from: data)
        } catch {
            return []
        }
    }

    func getRecentItems(limit: Int = 20) -> [ClipboardSyncItem] {
        Array(fetchItems().suffix(limit))
    }

    private func saveItems(_ items: [ClipboardSyncItem]) {
        do {
            let data = try JSONEncoder().encode(items)
            UserDefaults.standard.set(data, forKey: syncKey)
        } catch {
            print("Failed to save sync items: \(error)")
        }
    }
}
