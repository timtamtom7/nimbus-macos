import Foundation

struct NimbusExport: Codable {
    let version: String
    let exportDate: Date
    let favorites: [FavoriteItem]
    let smartPasteRules: [SmartPasteRule]
}

final class NimbusExportManager {
    static let shared = NimbusExportManager()

    private init() {}

    func exportToJSON() -> Data? {
        let export = NimbusExport(
            version: "R10",
            exportDate: Date(),
            favorites: FavoritesManager.shared.fetchFavorites(),
            smartPasteRules: SmartPasteManager.shared.fetchRules()
        )

        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            return try encoder.encode(export)
        } catch {
            print("Failed to encode export: \(error)")
            return nil
        }
    }

    func importFrom(_ data: Data) -> Bool {
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let export = try decoder.decode(NimbusExport.self, from: data)

            for favorite in export.favorites {
                FavoritesManager.shared.addFavorite(content: favorite.content, type: favorite.type, label: favorite.label)
            }

            for rule in export.smartPasteRules {
                SmartPasteManager.shared.saveRule(rule)
            }

            return true
        } catch {
            print("Failed to import: \(error)")
            return false
        }
    }

    func saveExportToFile() -> URL? {
        guard let data = exportToJSON() else { return nil }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let fileName = "Nimbus-Backup-\(dateFormatter.string(from: Date())).json"

        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(fileName)

        do {
            try data.write(to: fileURL)
            return fileURL
        } catch {
            print("Failed to write export file: \(error)")
            return nil
        }
    }
}
