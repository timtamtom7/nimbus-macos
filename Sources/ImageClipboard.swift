import Foundation

struct ImageClipboardItem: Identifiable, Codable {
    let id: UUID
    var imageData: Data
    var thumbnailData: Data
    var timestamp: Date
    var size: CGSize
}

final class ImageClipboardManager {
    static let shared = ImageClipboardManager()

    private let imagesKey = "clipboardImages"
    private let maxImages = 50

    private init() {}

    func saveImage(_ imageData: Data, thumbnail: Data, size: CGSize) {
        let item = ImageClipboardItem(
            id: UUID(),
            imageData: imageData,
            thumbnailData: thumbnail,
            timestamp: Date(),
            size: size
        )

        var items = fetchImages()
        items.append(item)

        if items.count > maxImages {
            items = Array(items.suffix(maxImages))
        }

        saveImages(items)
    }

    func fetchImages() -> [ImageClipboardItem] {
        guard let data = UserDefaults.standard.data(forKey: imagesKey) else { return [] }
        do {
            return try JSONDecoder().decode([ImageClipboardItem].self, from: data)
        } catch {
            return []
        }
    }

    func deleteImage(_ id: UUID) {
        var items = fetchImages()
        items.removeAll { $0.id == id }
        saveImages(items)
    }

    private func saveImages(_ items: [ImageClipboardItem]) {
        do {
            let data = try JSONEncoder().encode(items)
            UserDefaults.standard.set(data, forKey: imagesKey)
        } catch {
            print("Failed to save clipboard images: \(error)")
        }
    }
}
