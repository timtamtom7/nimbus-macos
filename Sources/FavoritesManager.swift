import Foundation

struct FavoriteItem: Identifiable, Codable {
    let id: UUID
    var content: String
    var type: String
    var label: String
    var createdAt: Date
}

final class FavoritesManager {
    static let shared = FavoritesManager()

    private let favoritesKey = "clipboardFavorites"

    private init() {}

    func addFavorite(content: String, type: String, label: String) {
        let item = FavoriteItem(
            id: UUID(),
            content: content,
            type: type,
            label: label,
            createdAt: Date()
        )

        var favorites = fetchFavorites()
        favorites.append(item)
        saveFavorites(favorites)
    }

    func fetchFavorites() -> [FavoriteItem] {
        guard let data = UserDefaults.standard.data(forKey: favoritesKey) else { return [] }
        do {
            return try JSONDecoder().decode([FavoriteItem].self, from: data)
        } catch {
            return []
        }
    }

    func deleteFavorite(_ id: UUID) {
        var favorites = fetchFavorites()
        favorites.removeAll { $0.id == id }
        saveFavorites(favorites)
    }

    private func saveFavorites(_ favorites: [FavoriteItem]) {
        do {
            let data = try JSONEncoder().encode(favorites)
            UserDefaults.standard.set(data, forKey: favoritesKey)
        } catch {
            print("Failed to save favorites: \(error)")
        }
    }
}
